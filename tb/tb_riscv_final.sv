
`timescale 1ns/1ps

module tb_riscv_final;

    logic clk = 0;
    logic rst = 1;

    logic [31:0] pc_debug;
    logic [31:0] instruction_debug;

    integer tests = 0;
    integer errors = 0;
    integer cycle;

    riscv_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug)
    );

    always #5 clk = ~clk;

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
        $display("ETAPE 15 : VALIDATION GLOBALE");
        $display("==============================");

        // Initialisation
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // Verification de la sequence du PC
        // Les adresses 44, 52 et 60
        // doivent etre ignorees.

        for (cycle = 0; cycle < 15; cycle = cycle + 1) begin

            case (cycle)
                0:  check_value(pc_debug,  0, "PC 0");
                1:  check_value(pc_debug,  4, "PC 4");
                2:  check_value(pc_debug,  8, "PC 8");
                3:  check_value(pc_debug, 12, "PC 12");
                4:  check_value(pc_debug, 16, "PC 16");
                5:  check_value(pc_debug, 20, "PC 20");
                6:  check_value(pc_debug, 24, "PC 24");
                7:  check_value(pc_debug, 28, "PC 28");
                8:  check_value(pc_debug, 32, "PC 32");
                9:  check_value(pc_debug, 36, "PC 36");
                10: check_value(pc_debug, 40, "BEQ");
                11: check_value(pc_debug, 48, "BNE");
                12: check_value(pc_debug, 56, "JAL");
                13: check_value(pc_debug, 64, "PC 64");
                14: check_value(pc_debug, 68, "PC 68");
            endcase

            @(posedge clk);
            #1;
        end

        // Registres et operations ALU
        check_value(dut.u_regfile.registers[1],
                    32'd64, "x1 = 64");

        check_value(dut.u_regfile.registers[2],
                    32'd10, "x2 = 10");

        check_value(dut.u_regfile.registers[3],
                    32'd3, "x3 = 3");

        check_value(dut.u_regfile.registers[4],
                    32'd13, "ADD");

        check_value(dut.u_regfile.registers[5],
                    32'd7, "SUB");

        check_value(dut.u_regfile.registers[6],
                    32'd2, "AND");

        check_value(dut.u_regfile.registers[7],
                    32'd11, "OR");

        check_value(dut.u_regfile.registers[8],
                    32'd9, "XOR");

        // Memoire
        check_value(dut.u_dmem.memory[16],
                    32'd13, "SW memoire");

        check_value(dut.u_regfile.registers[9],
                    32'd13, "LW memoire");

        // Instructions ignorees
        check_value(dut.u_regfile.registers[10],
                    32'd0, "BEQ ignore x10");

        check_value(dut.u_regfile.registers[11],
                    32'd0, "BNE ignore x11");

        // JAL : adresse de retour = 60
        check_value(dut.u_regfile.registers[12],
                    32'd60, "JAL retour");

        check_value(dut.u_regfile.registers[13],
                    32'd0, "JAL ignore x13");

        // Dernieres instructions
        check_value(dut.u_regfile.registers[14],
                    32'd42, "x14 = 42");

        check_value(dut.u_regfile.registers[15],
                    32'd7, "x15 = 7");

        $display("==============================");
        $display("TESTS : %0d", tests);
        $display("ERREURS : %0d", errors);

        if (errors == 0)
            $display("ETAPE 15 REUSSIE");
        else
            $display("ETAPE 15 ECHOUEE");

        $display("==============================");

        $finish;
    end

endmodule