`timescale 1ns/1ps

module tb_riscv_pipeline_sva;

    logic clk = 1'b0;
    logic rst = 1'b1;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire stall_debug;
    wire forwarding_debug;
    wire flush_debug;

    integer errors = 0;
    integer checks = 0;
    integer stalls = 0;
    integer forwards = 0;
    integer flushes = 0;
    integer i;

    // =========================================
    // 1. PROCESSEUR A VERIFIER
    // =========================================

    riscv_pipeline_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .stall_debug(stall_debug),
        .forwarding_debug(forwarding_debug),
        .flush_debug(flush_debug)
    );

    // Periode d'horloge = 10 ns
    always #5 clk = ~clk;

    // =========================================
    // 2. ENCODAGE DES INSTRUCTIONS
    // =========================================

    function automatic [31:0] I(
        input integer imm,
        input [4:0] rs1,
        input [2:0] f3,
        input [4:0] rd,
        input [6:0] op
    );
        I = {imm[11:0], rs1, f3, rd, op};
    endfunction

    function automatic [31:0] R(
        input [6:0] f7,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3,
        input [4:0] rd
    );
        R = {f7, rs2, rs1, f3, rd, 7'b0110011};
    endfunction

    function automatic [31:0] S(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3
    );
        S = {
            imm[11:5], rs2, rs1, f3,
            imm[4:0], 7'b0100011
        };
    endfunction

    function automatic [31:0] B(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3
    );
        B = {
            imm[12], imm[10:5],
            rs2, rs1, f3,
            imm[4:1], imm[11],
            7'b1100011
        };
    endfunction

    // =========================================
    // 3. COMPTEURS DE COUVERTURE
    // =========================================

    always @(posedge clk) begin
        if (!rst) begin
            if (stall_debug)
                stalls = stalls + 1;

            if (forwarding_debug)
                forwards = forwards + 1;

            if (flush_debug)
                flushes = flushes + 1;
        end
    end

    // =========================================
    // 4. ASSERTIONS IMMEDIATES
    // =========================================
    //
    // Les controles sont effectues avant et
    // apres chaque front montant.
    //
    // #1 laisse le temps aux registres
    // de mettre a jour leurs sorties.
    //
    // =========================================

    always @(posedge clk) begin : CHECK_PIPELINE

        reg [31:0] old_pc;
        reg [31:0] old_pc_d;
        reg [31:0] old_instruction_d;

        reg old_stall;
        reg old_flush;
        reg old_hazard;

        reg [1:0] old_forward_a;
        reg [1:0] old_forward_b;

        reg [31:0] old_operand_a;
        reg [31:0] old_operand_b;
        reg [31:0] old_alu_m;
        reg [31:0] old_wb_data;
        reg [31:0] old_rs1_e;
        reg [31:0] old_rs2_e;

        reg old_ex_match_a;
        reg old_ex_match_b;
        reg old_wb_match_a;
        reg old_wb_match_b;

        if (!rst) begin

            // Capturer les valeurs avant le front.
            old_pc = dut.pc_f;
            old_pc_d = dut.pc_d;
            old_instruction_d = dut.instruction_d;

            old_stall = stall_debug;
            old_flush = flush_debug;
            old_hazard = dut.hazard_bubble;

            old_forward_a = dut.forward_a;
            old_forward_b = dut.forward_b;

            old_operand_a = dut.operand_a_ex;
            old_operand_b = dut.operand_b_ex;

            old_alu_m = dut.alu_m;
            old_wb_data = dut.wb_data;
            old_rs1_e = dut.rs1_e;
            old_rs2_e = dut.rs2_e;

            // Les conditions de correspondance
            // sont calculees independamment
            // des sorties de la Forwarding Unit.

            old_ex_match_a =
                dut.reg_write_m &&
                !dut.mem_to_reg_m &&
                (dut.rd_m != 5'd0) &&
                (dut.rd_m == dut.rs1_idx_e);

            old_ex_match_b =
                dut.reg_write_m &&
                !dut.mem_to_reg_m &&
                (dut.rd_m != 5'd0) &&
                (dut.rd_m == dut.rs2_idx_e);

            old_wb_match_a =
                dut.wb_we &&
                (dut.rd_w != 5'd0) &&
                (dut.rd_w == dut.rs1_idx_e);

            old_wb_match_b =
                dut.wb_we &&
                (dut.rd_w != 5'd0) &&
                (dut.rd_w == dut.rs2_idx_e);

            // ---------------------------------
            // SVA 1 : x0 doit toujours etre zero
            // ---------------------------------

            checks = checks + 1;

            assert (dut.u_regfile.registers[0] === 32'd0)
            else begin
                $error("SVA 1 FAIL : x0 != 0");
                errors = errors + 1;
            end

            // ---------------------------------
            // SVA 5 : PRIORITE EX/MEM
            // ---------------------------------

            if (old_ex_match_a) begin
                checks = checks + 1;

                assert (
                    old_forward_a === 2'b10 &&
                    old_operand_a === old_alu_m
                )
                else begin
                    $error(
                        "SVA 5 FAIL : forwarding A EX/MEM"
                    );
                    errors = errors + 1;
                end
            end

            if (old_ex_match_b) begin
                checks = checks + 1;

                assert (
                    old_forward_b === 2'b10 &&
                    old_operand_b === old_alu_m
                )
                else begin
                    $error(
                        "SVA 5 FAIL : forwarding B EX/MEM"
                    );
                    errors = errors + 1;
                end
            end

            // ---------------------------------
            // SVA 6 : FORWARDING MEM/WB
            // ---------------------------------

            if (!old_ex_match_a && old_wb_match_a) begin
                checks = checks + 1;

                assert (
                    old_forward_a === 2'b01 &&
                    old_operand_a === old_wb_data
                )
                else begin
                    $error(
                        "SVA 6 FAIL : forwarding A MEM/WB"
                    );
                    errors = errors + 1;
                end
            end

            if (!old_ex_match_b && old_wb_match_b) begin
                checks = checks + 1;

                assert (
                    old_forward_b === 2'b01 &&
                    old_operand_b === old_wb_data
                )
                else begin
                    $error(
                        "SVA 6 FAIL : forwarding B MEM/WB"
                    );
                    errors = errors + 1;
                end
            end

            // ---------------------------------
            // SVA 7 : PAS D'ECRITURE DANS x0
            // ---------------------------------

            checks = checks + 1;

            assert (
                !(dut.wb_we && dut.rd_w == 5'd0)
            )
            else begin
                $error("SVA 7 FAIL : ecriture x0");
                errors = errors + 1;
            end

            // ---------------------------------
            // SVA 8 : LOAD-USE HAZARD
            // ---------------------------------

            if (dut.mem_read_e &&
                dut.rd_e != 5'd0 &&
                ((dut.rd_e == dut.hazard_rs1_d) ||
                 (dut.rd_e == dut.hazard_rs2_d))) begin

                checks = checks + 1;

                assert (
                    dut.pc_write === 1'b0 &&
                    dut.if_id_write === 1'b0 &&
                    dut.hazard_bubble === 1'b1
                )
                else begin
                    $error(
                        "SVA 8 FAIL : load-use hazard"
                    );
                    errors = errors + 1;
                end
            end

            // ---------------------------------
            // Attendre les mises a jour
            // ---------------------------------

            #1;

            // ---------------------------------
            // SVA 2 : PC STABLE PENDANT STALL
            // ---------------------------------

            if (old_stall && !old_flush) begin
                checks = checks + 1;

                assert (dut.pc_f === old_pc)
                else begin
                    $error(
                        "SVA 2 FAIL : PC modifie pendant stall"
                    );
                    errors = errors + 1;
                end

                // IF/ID doit egalement rester stable.

                checks = checks + 1;

                assert (
                    dut.pc_d === old_pc_d &&
                    dut.instruction_d === old_instruction_d
                )
                else begin
                    $error(
                        "SVA 2 FAIL : IF/ID non stable"
                    );
                    errors = errors + 1;
                end
            end

            // ---------------------------------
            // SVA 3 : FLUSH IF/ID
            // ---------------------------------

            if (old_flush) begin
                checks = checks + 1;

                assert (
                    dut.pc_d === 32'd0 &&
                    dut.instruction_d === 32'd0
                )
                else begin
                    $error(
                        "SVA 3 FAIL : IF/ID non vide apres flush"
                    );
                    errors = errors + 1;
                end
            end

            // ---------------------------------
            // SVA 4 : BULLE ID/EX
            // ---------------------------------

            if (old_flush || old_hazard) begin
                checks = checks + 1;

                assert (
                    dut.reg_write_e === 1'b0 &&
                    dut.mem_read_e === 1'b0 &&
                    dut.mem_write_e === 1'b0 &&
                    dut.branch_e === 1'b0 &&
                    dut.jump_e === 1'b0
                )
                else begin
                    $error(
                        "SVA 4 FAIL : bulle ID/EX incorrecte"
                    );
                    errors = errors + 1;
                end
            end

        end
    end

    // =========================================
    // 5. VERIFICATION DES RESULTATS
    // =========================================

    task automatic check_reg(
        input integer idx,
        input [31:0] expected
    );
        begin
            checks = checks + 1;

            if (dut.u_regfile.registers[idx] !== expected) begin
                $display(
                    "FAIL x%0d : obtenu=%h attendu=%h",
                    idx,
                    dut.u_regfile.registers[idx],
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS x%0d = %h",
                    idx,
                    expected
                );
            end
        end
    endtask

    task automatic check_mem(
        input integer idx,
        input [31:0] expected
    );
        begin
            checks = checks + 1;

            if (dut.u_dmem.memory[idx] !== expected) begin
                $display(
                    "FAIL MEM[%0d] : obtenu=%h attendu=%h",
                    idx,
                    dut.u_dmem.memory[idx],
                    expected
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS MEM[%0d] = %h",
                    idx,
                    expected
                );
            end
        end
    endtask

    // =========================================
    // 6. PROGRAMME DE TEST
    // =========================================

    initial begin

        #1;

        // Remplir la ROM avec des NOP.

        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        // ADDI x1, x0, 5
        dut.u_imem.memory[0] =
            I(5, 0, 3'b000, 1, 7'b0010011);

        // ADDI x2, x0, 7
        dut.u_imem.memory[1] =
            I(7, 0, 3'b000, 2, 7'b0010011);

        // ADD x3, x1, x2
        // x3 = 12
        dut.u_imem.memory[2] =
            R(0, 2, 1, 3'b000, 3);

        // ADDI x3, x3, 1
        // x3 = 13
        dut.u_imem.memory[3] =
            I(1, 3, 3'b000, 3, 7'b0010011);

        // SW x3, 0(x0)
        dut.u_imem.memory[4] =
            S(0, 3, 0, 3'b010);

        // LW x4, 0(x0)
        // x4 = 13
        dut.u_imem.memory[5] =
            I(0, 0, 3'b010, 4, 7'b0000011);

        // ADD x5, x4, x1
        // x5 = 18, avec stall load-use
        dut.u_imem.memory[6] =
            R(0, 1, 4, 3'b000, 5);

        // BEQ x5, x5, +8
        dut.u_imem.memory[7] =
            B(8, 5, 5, 3'b000);

        // Instruction a eliminer
        dut.u_imem.memory[8] =
            I(99, 0, 3'b000, 6, 7'b0010011);

        // ADDI x6, x0, 42
        dut.u_imem.memory[9] =
            I(42, 0, 3'b000, 6, 7'b0010011);

        // Ecriture dans x0 : doit etre ignoree
        dut.u_imem.memory[10] =
            I(123, 0, 3'b000, 0, 7'b0010011);

        // ADDI x7, x6, 1
        // x7 = 43
        dut.u_imem.memory[11] =
            I(1, 6, 3'b000, 7, 7'b0010011);

        // SW x7, 4(x0)
        dut.u_imem.memory[12] =
            S(4, 7, 0, 3'b010);

        // LW x8, 4(x0)
        dut.u_imem.memory[13] =
            I(4, 0, 3'b010, 8, 7'b0000011);

        // ADDI x9, x8, 2
        // x9 = 45, second load-use
        dut.u_imem.memory[14] =
            I(2, 8, 3'b000, 9, 7'b0010011);

        // ADD x10, x9, x5
        // x10 = 63
        dut.u_imem.memory[15] =
            R(0, 5, 9, 3'b000, 10);

        // =====================================
        // RESET
        // =====================================

        #11;
        rst = 1'b0;

        // Executer le programme
        #500;

        // =====================================
        // VERIFICATION FINALE
        // =====================================

        $display("");
        $display("====================================");
        $display(" ETAPE 26 - ASSERTIONS SYSTEMVERILOG");
        $display("====================================");

        check_reg(0, 0);
        check_reg(1, 5);
        check_reg(2, 7);
        check_reg(3, 13);
        check_reg(4, 13);
        check_reg(5, 18);
        check_reg(6, 42);
        check_reg(7, 43);
        check_reg(8, 43);
        check_reg(9, 45);
        check_reg(10, 63);

        check_mem(0, 13);
        check_mem(1, 43);

        // Verification de la couverture

        checks = checks + 1;

        if (stalls < 2) begin
            $display("FAIL : stalls insuffisants");
            errors = errors + 1;
        end
        else
            $display("PASS : stalls detectes");

        checks = checks + 1;

        if (forwards < 2) begin
            $display("FAIL : forwarding insuffisant");
            errors = errors + 1;
        end
        else
            $display("PASS : forwarding detecte");

        checks = checks + 1;

        if (flushes < 1) begin
            $display("FAIL : aucun flush");
            errors = errors + 1;
        end
        else
            $display("PASS : flush detecte");

        // =====================================
        // BILAN
        // =====================================

        $display("");
        $display("Assertions et controles = %0d", checks);
        $display("Stalls                  = %0d", stalls);
        $display("Forwardings             = %0d", forwards);
        $display("Flushs                  = %0d", flushes);
        $display("Erreurs                 = %0d", errors);

        if (errors == 0)
            $display(
                "ETAPE 26 REUSSIE - 0 ERREUR"
            );
        else
            $display(
                "ETAPE 26 ECHOUEE - %0d ERREUR(S)",
                errors
            );

        $stop;

    end

endmodule