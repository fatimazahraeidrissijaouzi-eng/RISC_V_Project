`timescale 1ns/1ps

module tb_riscv_pipeline_core;

    logic clk = 0;
    logic rst = 1;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;

    wire stall_debug;
    wire forwarding_debug;
    wire flush_debug;

    integer errors = 0;
    integer stalls = 0;
    integer forwards = 0;
    integer flushes = 0;
    integer i;

    // =====================================
    // DUT : PROCESSEUR PIPELINE
    // =====================================

    riscv_pipeline_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .stall_debug(stall_debug),
        .forwarding_debug(forwarding_debug),
        .flush_debug(flush_debug)
    );

    // Horloge : periode de 10 ns
    always #5 clk = ~clk;

    // =====================================
    // ENCODAGE DES INSTRUCTIONS RISC-V
    // =====================================

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
        R = {
            f7,
            rs2,
            rs1,
            f3,
            rd,
            7'b0110011
        };
    endfunction

    function automatic [31:0] S(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3
    );
        S = {
            imm[11:5],
            rs2,
            rs1,
            f3,
            imm[4:0],
            7'b0100011
        };
    endfunction

    function automatic [31:0] B(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3
    );
        B = {
            imm[12],
            imm[10:5],
            rs2,
            rs1,
            f3,
            imm[4:1],
            imm[11],
            7'b1100011
        };
    endfunction

    function automatic [31:0] J(
        input integer imm,
        input [4:0] rd
    );
        J = {
            imm[20],
            imm[10:1],
            imm[11],
            imm[19:12],
            rd,
            7'b1101111
        };
    endfunction

    // =====================================
    // VERIFICATION DES REGISTRES
    // =====================================

    task automatic check_reg(
        input integer idx,
        input [31:0] expected
    );
        begin
            if (dut.u_regfile.registers[idx] !== expected) begin
                $display(
                    "ECHEC x%0d : obtenu=%h attendu=%h",
                    idx,
                    dut.u_regfile.registers[idx],
                    expected
                );

                errors = errors + 1;
            end
            else begin
                $display(
                    "OK x%0d = %h",
                    idx,
                    expected
                );
            end
        end
    endtask

    // =====================================
    // COMPTEURS DES EVENEMENTS
    // =====================================

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

    // =====================================
    // PROGRAMME DE TEST
    // =====================================

    initial begin

        // Attendre l'initialisation de la ROM
        #1;

        // Remplir la memoire avec des NOP
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        // ---------------------------------
        // TEST 1 : ADDI
        // ---------------------------------

        // ADDI x1, x0, 5
        dut.u_imem.memory[0] =
            I(5, 0, 3'b000, 1, 7'b0010011);

        // ADDI x2, x0, 7
        dut.u_imem.memory[1] =
            I(7, 0, 3'b000, 2, 7'b0010011);

        // ---------------------------------
        // TEST 2 : FORWARDING
        // ---------------------------------

        // ADD x3, x1, x2
        // Resultat attendu : x3 = 12
        dut.u_imem.memory[2] =
            R(0, 2, 1, 3'b000, 3);

        // ---------------------------------
        // TEST 3 : STORE
        // ---------------------------------

        // SW x3, 0(x0)
        // MEM[0] = 12
        dut.u_imem.memory[3] =
            S(0, 3, 0, 3'b010);

        // ---------------------------------
        // TEST 4 : LOAD
        // ---------------------------------

        // LW x4, 0(x0)
        // x4 = 12
        dut.u_imem.memory[4] =
            I(0, 0, 3'b010, 4, 7'b0000011);

        // ---------------------------------
        // TEST 5 : LOAD-USE HAZARD
        // ---------------------------------

        // ADD x5, x4, x1
        // x5 = 17
        dut.u_imem.memory[5] =
            R(0, 1, 4, 3'b000, 5);

        // ---------------------------------
        // TEST 6 : BRANCH
        // ---------------------------------

        // BEQ x5, x5, +8
        dut.u_imem.memory[6] =
            B(8, 5, 5, 3'b000);

        // Instruction a ignorer
        dut.u_imem.memory[7] =
            I(99, 0, 3'b000, 6, 7'b0010011);

        // ADDI x6, x0, 42
        dut.u_imem.memory[8] =
            I(42, 0, 3'b000, 6, 7'b0010011);

        // ---------------------------------
        // TEST 7 : JAL
        // ---------------------------------

        // JAL x7, +8
        dut.u_imem.memory[9] =
            J(8, 7);

        // Instruction a ignorer
        dut.u_imem.memory[10] =
            I(99, 0, 3'b000, 8, 7'b0010011);

        // ADDI x8, x0, 11
        dut.u_imem.memory[11] =
            I(11, 0, 3'b000, 8, 7'b0010011);

        // ---------------------------------
        // TEST 8 : LUI
        // ---------------------------------

        // LUI x9, 0x12345
        dut.u_imem.memory[12] =
            {20'h12345, 5'd9, 7'b0110111};

        // ---------------------------------
        // TEST 9 : AUIPC
        // ---------------------------------

        // AUIPC x10, 0
        dut.u_imem.memory[13] =
            {20'd0, 5'd10, 7'b0010111};

        // ---------------------------------
        // TEST 10 : JALR
        // ---------------------------------

        // ADDI x11, x0, 72
        dut.u_imem.memory[14] =
            I(72, 0, 3'b000, 11, 7'b0010011);

        // JALR x12, x11, 0
        dut.u_imem.memory[15] =
            I(0, 11, 3'b000, 12, 7'b1100111);

        // Instructions a ignorer
        dut.u_imem.memory[16] =
            I(99, 0, 3'b000, 13, 7'b0010011);

        dut.u_imem.memory[17] =
            I(98, 0, 3'b000, 13, 7'b0010011);

        // ADDI x13, x0, 77
        dut.u_imem.memory[18] =
            I(77, 0, 3'b000, 13, 7'b0010011);

        // =====================================
        // RESET ET SIMULATION
        // =====================================

        #11;
        rst = 0;

        // Laisser le processeur executer
        #500;

        // =====================================
        // VERIFICATION DES RESULTATS
        // =====================================

        $display("");
        $display("========= BILAN ETAPE 24 =========");

        check_reg(1, 5);
        check_reg(2, 7);
        check_reg(3, 12);
        check_reg(4, 12);
        check_reg(5, 17);
        check_reg(6, 42);
        check_reg(7, 40);
        check_reg(8, 11);
        check_reg(9, 32'h12345000);
        check_reg(10, 52);
        check_reg(11, 72);
        check_reg(12, 64);
        check_reg(13, 77);

        // =====================================
        // VERIFICATION DE LA MEMOIRE
        // =====================================

        if (dut.u_dmem.memory[0] !== 32'd12) begin

            $display(
                "ECHEC MEM[0] : obtenu=%h attendu=0000000c",
                dut.u_dmem.memory[0]
            );

            errors = errors + 1;

        end
        else begin
            $display("OK MEM[0] = 12");
        end

        // =====================================
        // VERIFICATION DES HAZARDS
        // =====================================

        $display("");
        $display("Stalls = %0d", stalls);
        $display("Forwarding = %0d", forwards);
        $display("Flush = %0d", flushes);

        if (stalls < 1) begin
            $display("ECHEC : aucun stall detecte");
            errors = errors + 1;
        end

        if (forwards < 1) begin
            $display("ECHEC : aucun forwarding detecte");
            errors = errors + 1;
        end

        if (flushes < 3) begin
            $display("ECHEC : flush insuffisant");
            errors = errors + 1;
        end

        // =====================================
        // RESULTAT FINAL
        // =====================================

        $display("");
        $display("================================");

        if (errors == 0)
            $display("ETAPE 24 REUSSIE - 0 ERREUR");
        else
            $display(
                "ETAPE 24 ECHOUEE - %0d ERREUR(S)",
                errors
            );

        $display("================================");

        $stop;

    end

endmodules