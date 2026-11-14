
`timescale 1ns/1ps

module tb_riscv_memory;

    logic clk = 0;
    logic rst = 1;

    logic [31:0] pc_debug;
    logic [31:0] instruction_debug;

    integer tests = 0;
    integer errors = 0;
    integer i;

    riscv_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug)
    );

    // Horloge : 10 ns
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

        $display("============================");
        $display("TEST MEMOIRE RISC-V");
        $display("ETAPE 13");
        $display("============================");

        // Reset
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // Verification des 15 instructions
        for (i = 0; i < 15; i = i + 1) begin
            check_value(
                pc_debug,
                i * 4,
                "Program Counter"
            );

            @(posedge clk);
            #1;
        end

        // Verification des registres
        check_value(
            dut.u_regfile.registers[1],
            32'd64,
            "x1 = 64"
        );

        check_value(
            dut.u_regfile.registers[2],
            32'hFFFFFFFF,
            "x2 = -1"
        );

        check_value(
            dut.u_regfile.registers[3],
            32'hFFFFFFFF,
            "LB"
        );

        check_value(
            dut.u_regfile.registers[4],
            32'h000000FF,
            "LBU"
        );

        check_value(
            dut.u_regfile.registers[5],
            32'hFFFFFFFF,
            "LH"
        );

        check_value(
            dut.u_regfile.registers[6],
            32'h0000FFFF,
            "LHU"
        );

        check_value(
            dut.u_regfile.registers[7],
            32'hFFFFFFFF,
            "LW"
        );

        check_value(
            dut.u_regfile.registers[8],
            32'd18,
            "x8 = 18"
        );

        check_value(
            dut.u_regfile.registers[9],
            32'd18,
            "SB puis LBU"
        );

        check_value(
            dut.u_regfile.registers[10],
            32'h00000345,
            "x10 = 0x345"
        );

        check_value(
            dut.u_regfile.registers[11],
            32'h00000345,
            "SH puis LHU"
        );

        check_value(
            dut.u_regfile.registers[12],
            32'h034512FF,
            "LW final"
        );

        // Verification de la memoire
        check_value(
            dut.u_dmem.memory[16],
            32'h034512FF,
            "Memoire adresse 64"
        );

        $display("============================");
        $display("TESTS : %0d", tests);
        $display("ERREURS : %0d", errors);

        if (errors == 0)
            $display("ETAPE 13 REUSSIE");
        else
            $display("ETAPE 13 ECHOUEE");

        $display("============================");

        $finish;

    end

endmodule