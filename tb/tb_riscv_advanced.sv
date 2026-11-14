
`timescale 1ns/1ps

module tb_riscv_advanced;

    logic clk = 0;
    logic rst = 1;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;

    integer tests = 0;
    integer errors = 0;
    integer cycle;

    // Processeur RISC-V
    riscv_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug)
    );

    // Horloge : periode 10 ns
    always #5 clk = ~clk;

    // Verification automatique
    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string name
    );
        begin
            tests = tests + 1;

            if (actual === expected)
                $display("OK : %s", name);
            else begin
                errors = errors + 1;
                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    name, expected, actual
                );
            end
        end
    endtask

    initial begin

        $display("==============================");
        $display("ETAPE 17 : VERIFICATION AVANCEE");
        $display("==============================");

        // Initialisation
        rst = 1;

        #1;

        // Chargement du programme
        $readmemh(
            "program/program_etape17.hex",
            dut.u_imem.memory
        );

        // Reset pendant deux cycles
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // =====================================
        // TEST 1 : PROGRAM COUNTER
        // =====================================

        for (cycle = 0; cycle < 15;
             cycle = cycle + 1) begin

            case (cycle)
                0:  check_value(pc_debug, 0, "PC 0");
                1:  check_value(pc_debug, 4, "PC 4");
                2:  check_value(pc_debug, 8, "PC 8");
                3:  check_value(pc_debug, 12, "PC 12");
                4:  check_value(pc_debug, 16, "PC 16");
                5:  check_value(pc_debug, 20, "PC 20");
                6:  check_value(pc_debug, 24, "PC 24");
                7:  check_value(pc_debug, 28, "PC 28");
                8:  check_value(pc_debug, 32, "PC SW");
                9:  check_value(pc_debug, 36, "PC LW");
                10: check_value(pc_debug, 40, "PC BEQ");
                11: check_value(pc_debug, 48, "PC BNE");
                12: check_value(pc_debug, 56, "PC JAL");
                13: check_value(pc_debug, 64, "PC 64");
                14: check_value(pc_debug, 68, "PC 68");
            endcase

            @(posedge clk);
            #1;
        end

        // =====================================
        // TEST 2 : REGISTRES
        // =====================================

        check_value(
            dut.u_regfile.registers[0],
            32'd0, "x0 toujours zero"
        );

        check_value(
            dut.u_regfile.registers[1],
            32'd64, "x1 = 64"
        );

        check_value(
            dut.u_regfile.registers[2],
            32'd5, "x2 = 5"
        );

        check_value(
            dut.u_regfile.registers[3],
            32'd3, "x3 = 3"
        );

        // =====================================
        // TEST 3 : OPERATIONS ALU
        // =====================================

        check_value(
            dut.u_regfile.registers[4],
            32'd2, "SUB positif"
        );

        check_value(
            dut.u_regfile.registers[5],
            32'hFFFFFFFE, "SUB negatif"
        );

        check_value(
            dut.u_regfile.registers[6],
            32'd1, "AND"
        );

        check_value(
            dut.u_regfile.registers[7],
            32'd7, "OR"
        );

        check_value(
            dut.u_regfile.registers[8],
            32'd6, "XOR"
        );

        // =====================================
        // TEST 4 : MEMOIRE
        // =====================================

        check_value(
            dut.u_dmem.memory[16],
            32'd2, "SW adresse 64"
        );

        check_value(
            dut.u_regfile.registers[9],
            32'd2, "LW adresse 64"
        );

        // =====================================
        // TEST 5 : BRANCHEMENTS
        // =====================================

        check_value(
            dut.u_regfile.registers[10],
            32'd0, "BEQ ignore x10"
        );

        check_value(
            dut.u_regfile.registers[11],
            32'd0, "BNE ignore x11"
        );

        // =====================================
        // TEST 6 : SAUT JAL
        // =====================================

        check_value(
            dut.u_regfile.registers[12],
            32'd60, "JAL retour"
        );

        check_value(
            dut.u_regfile.registers[13],
            32'd0, "JAL ignore x13"
        );

        // =====================================
        // TEST 7 : DERNIERES INSTRUCTIONS
        // =====================================

        check_value(
            dut.u_regfile.registers[14],
            32'd42, "x14 = 42"
        );

        check_value(
            dut.u_regfile.registers[15],
            32'd7, "x15 = 7"
        );

        // =====================================
        // TEST 8 : INSTRUCTION INVALIDE
        // =====================================

        check_value(
            pc_debug,
            32'd72, "PC instruction invalide"
        );

        check_value(
            instruction_debug,
            32'hFFFFFFFF, "Instruction invalide"
        );

        check_value(
            {31'b0, dut.instruction_valid},
            32'd0, "Instruction rejetee"
        );

        check_value(
            {31'b0, dut.reg_write_enable},
            32'd0, "Ecriture registre bloquee"
        );

        check_value(
            {31'b0, dut.mem_write_enable},
            32'd0, "Ecriture memoire bloquee"
        );

        // =====================================
        // RESULTATS
        // =====================================

        $display("==============================");
        $display("TESTS  : %0d", tests);
        $display("ERREURS: %0d", errors);

        if (errors == 0)
            $display("ETAPE 17 REUSSIE");
        else
            $display("ETAPE 17 ECHOUEE");

        $display("==============================");

        $finish;

    end

endmodule