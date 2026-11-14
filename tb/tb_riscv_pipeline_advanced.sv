`timescale 1ns/1ps

module tb_riscv_pipeline_advanced;

    logic clk = 0;
    logic rst = 1;

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
    // 1. INSTANCIATION DU PROCESSEUR
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

    // Horloge : periode 10 ns
    always #5 clk = ~clk;

    // =========================================
    // 2. FONCTIONS D'ENCODAGE RISC-V
    // =========================================

    // I-TYPE
    function automatic [31:0] I(
        input integer imm,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        I = {
            imm[11:0],
            rs1,
            funct3,
            rd,
            opcode
        };
    endfunction

    // R-TYPE
    function automatic [31:0] R(
        input [6:0] funct7,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd
    );
        R = {
            funct7,
            rs2,
            rs1,
            funct3,
            rd,
            7'b0110011
        };
    endfunction

    // S-TYPE
    function automatic [31:0] S(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3
    );
        S = {
            imm[11:5],
            rs2,
            rs1,
            funct3,
            imm[4:0],
            7'b0100011
        };
    endfunction

    // B-TYPE
    function automatic [31:0] B(
        input integer imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3
    );
        B = {
            imm[12],
            imm[10:5],
            rs2,
            rs1,
            funct3,
            imm[4:1],
            imm[11],
            7'b1100011
        };
    endfunction

    // J-TYPE
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

    // =========================================
    // 3. TACHE DE VERIFICATION
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
    // 4. COMPTEURS DES EVENEMENTS
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
    // 5. PROGRAMME DE TEST AVANCE
    // =========================================

    initial begin

        // Attendre l'initialisation de la ROM
        #1;

        // Remplir la memoire avec des NOP
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        // -------------------------------------
        // TEST 1 : DEPENDANCES ADDI
        // -------------------------------------

        // x1 = 5
        dut.u_imem.memory[0] =
            I(5, 0, 3'b000, 1, 7'b0010011);

        // x1 = x1 + 3 = 8
        dut.u_imem.memory[1] =
            I(3, 1, 3'b000, 1, 7'b0010011);

        // x2 = x1 + 2 = 10
        dut.u_imem.memory[2] =
            I(2, 1, 3'b000, 2, 7'b0010011);

        // -------------------------------------
        // TEST 2 : OPERATIONS ALU
        // -------------------------------------

        // x3 = x1 + x2 = 18
        dut.u_imem.memory[3] =
            R(0, 2, 1, 3'b000, 3);

        // x4 = x3 - x1 = 10
        dut.u_imem.memory[4] =
            R(7'b0100000, 1, 3, 3'b000, 4);

        // x5 = x3 AND x2 = 2
        dut.u_imem.memory[5] =
            R(0, 2, 3, 3'b111, 5);

        // x6 = x4 OR x5 = 10
        dut.u_imem.memory[6] =
            R(0, 5, 4, 3'b110, 6);

        // x7 = x6 XOR x5 = 8
        dut.u_imem.memory[7] =
            R(0, 5, 6, 3'b100, 7);

        // -------------------------------------
        // TEST 3 : DECALAGE
        // -------------------------------------

        // x8 = 1
        dut.u_imem.memory[8] =
            I(1, 0, 3'b000, 8, 7'b0010011);

        // x9 = 1 << 8 = 256
        dut.u_imem.memory[9] =
            R(0, 1, 8, 3'b001, 9);

        // -------------------------------------
        // TEST 4 : MEMOIRE
        // -------------------------------------

        // SW x9, 4(x0)
        // MEM[1] = 256
        dut.u_imem.memory[10] =
            S(4, 9, 0, 3'b010);

        // LW x10, 4(x0)
        // x10 = 256
        dut.u_imem.memory[11] =
            I(4, 0, 3'b010, 10, 7'b0000011);

        // ADD x11, x10, x1
        // x11 = 264
        // Test load-use
        dut.u_imem.memory[12] =
            R(0, 1, 10, 3'b000, 11);

        // SW x11, 8(x0)
        // MEM[2] = 264
        dut.u_imem.memory[13] =
            S(8, 11, 0, 3'b010);

        // LW x12, 8(x0)
        // x12 = 264
        dut.u_imem.memory[14] =
            I(8, 0, 3'b010, 12, 7'b0000011);

        // -------------------------------------
        // TEST 5 : BRANCH BEQ
        // -------------------------------------

        // BEQ x12, x11, +8
        // Branche prise
        dut.u_imem.memory[15] =
            B(8, 11, 12, 3'b000);

        // Instruction a ignorer
        dut.u_imem.memory[16] =
            I(99, 0, 3'b000, 13, 7'b0010011);

        // x13 = 33
        dut.u_imem.memory[17] =
            I(33, 0, 3'b000, 13, 7'b0010011);

        // -------------------------------------
        // TEST 6 : BNE NON PRIS
        // -------------------------------------

        // BNE x1, x1, +8
        // Branche NON prise
        dut.u_imem.memory[18] =
            B(8, 1, 1, 3'b001);

        // x14 = 44
        dut.u_imem.memory[19] =
            I(44, 0, 3'b000, 14, 7'b0010011);

        // -------------------------------------
        // TEST 7 : BNE PRIS
        // -------------------------------------

        // BNE x1, x2, +8
        // Branche prise
        dut.u_imem.memory[20] =
            B(8, 2, 1, 3'b001);

        // Instruction a ignorer
        dut.u_imem.memory[21] =
            I(99, 0, 3'b000, 15, 7'b0010011);

        // x15 = 55
        dut.u_imem.memory[22] =
            I(55, 0, 3'b000, 15, 7'b0010011);

        // -------------------------------------
        // TEST 8 : REGISTRE x0
        // -------------------------------------

        // Tentative d'ecriture dans x0
        // x0 doit rester egal a zero
        dut.u_imem.memory[23] =
            I(123, 0, 3'b000, 0, 7'b0010011);

        // -------------------------------------
        // TEST 9 : COMPARAISONS
        // -------------------------------------

        // x16 = -1
        dut.u_imem.memory[24] =
            I(-1, 0, 3'b000, 16, 7'b0010011);

        // SLT signe : -1 < 8
        // x17 = 1
        dut.u_imem.memory[25] =
            R(0, 1, 16, 3'b010, 17);

        // SLTU non signe :
        // 0xFFFFFFFF < 8 est faux
        // x18 = 0
        dut.u_imem.memory[26] =
            R(0, 1, 16, 3'b011, 18);

        // -------------------------------------
        // TEST 10 : LUI ET AUIPC
        // -------------------------------------

        // LUI x19, 0x12345
        dut.u_imem.memory[27] =
            {20'h12345, 5'd19, 7'b0110111};

        // AUIPC x20, 0
        // PC = 28 * 4 = 112
        dut.u_imem.memory[28] =
            {20'd0, 5'd20, 7'b0010111};

        // -------------------------------------
        // TEST 11 : JAL
        // -------------------------------------

        // JAL x21, +8
        // x21 = 120
        dut.u_imem.memory[29] =
            J(8, 21);

        // Instruction a ignorer
        dut.u_imem.memory[30] =
            I(99, 0, 3'b000, 22, 7'b0010011);

        // x22 = 66
        dut.u_imem.memory[31] =
            I(66, 0, 3'b000, 22, 7'b0010011);

        // -------------------------------------
        // TEST 12 : JALR
        // -------------------------------------

        // x23 = 144
        dut.u_imem.memory[32] =
            I(144, 0, 3'b000, 23, 7'b0010011);

        // JALR x24, x23, 0
        // Retour x24 = 136
        // Destination PC = 144
        dut.u_imem.memory[33] =
            I(0, 23, 3'b000, 24, 7'b1100111);

        // Instructions a ignorer
        dut.u_imem.memory[34] =
            I(99, 0, 3'b000, 25, 7'b0010011);

        dut.u_imem.memory[35] =
            I(98, 0, 3'b000, 25, 7'b0010011);

        // x25 = 77
        dut.u_imem.memory[36] =
            I(77, 0, 3'b000, 25, 7'b0010011);

        // x26 = 7
        dut.u_imem.memory[37] =
            I(7, 0, 3'b000, 26, 7'b0010011);

        // =====================================
        // 6. RESET ET EXECUTION
        // =====================================

        #11;
        rst = 0;

        // Laisser le programme se terminer
        #900;

        // =====================================
        // 7. VERIFICATIONS AUTOMATIQUES
        // =====================================

        $display("");
        $display("====================================");
        $display("  ETAPE 25 : TEST AVANCE RISC-V");
        $display("====================================");

        check_reg(0, 0);
        check_reg(1, 8);
        check_reg(2, 10);
        check_reg(3, 18);
        check_reg(4, 10);
        check_reg(5, 2);
        check_reg(6, 10);
        check_reg(7, 8);
        check_reg(8, 1);
        check_reg(9, 256);
        check_reg(10, 256);
        check_reg(11, 264);
        check_reg(12, 264);
        check_reg(13, 33);
        check_reg(14, 44);
        check_reg(15, 55);
        check_reg(16, 32'hFFFFFFFF);
        check_reg(17, 1);
        check_reg(18, 0);
        check_reg(19, 32'h12345000);
        check_reg(20, 112);
        check_reg(21, 120);
        check_reg(22, 66);
        check_reg(23, 144);
        check_reg(24, 136);
        check_reg(25, 77);
        check_reg(26, 7);

        // Verification de la memoire
        check_mem(1, 256);
        check_mem(2, 264);

        // =====================================
        // 8. VERIFICATION DES ALEAS
        // =====================================

        $display("");
        $display("Stalls     = %0d", stalls);
        $display("Forwarding = %0d", forwards);
        $display("Flush      = %0d", flushes);

        checks = checks + 1;

        if (stalls < 2) begin
            $display("FAIL : moins de 2 stalls");
            errors = errors + 1;
        end
        else
            $display("PASS : stalls detectes");

        checks = checks + 1;

        if (forwards < 5) begin
            $display("FAIL : forwarding insuffisant");
            errors = errors + 1;
        end
        else
            $display("PASS : forwarding detecte");

        checks = checks + 1;

        if (flushes < 4) begin
            $display("FAIL : flush insuffisant");
            errors = errors + 1;
        end
        else
            $display("PASS : flush detecte");

        // =====================================
        // 9. BILAN FINAL
        // =====================================

        $display("");
        $display("====================================");
        $display("VERIFICATIONS = %0d", checks);
        $display("ERREURS       = %0d", errors);

        if (errors == 0)
            $display(
                "ETAPE 25 REUSSIE - 0 ERREUR"
            );
        else
            $display(
                "ETAPE 25 ECHOUEE - %0d ERREUR(S)",
                errors
            );

        $display("====================================");

        $stop;

    end

endmodule