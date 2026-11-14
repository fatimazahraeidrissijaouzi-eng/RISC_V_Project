
`timescale 1ns/1ps

module tb_riscv_alu_integration;

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

        // Charger un programme different
        // sans modifier program.hex
        #1;
        $readmemh(
            "program/alu_advanced.hex",
            dut.u_imem.memory
        );

        $display("==============================");
        $display("TEST ALU DANS LE RISC-V");
        $display("==============================");

        // Reset du processeur
        repeat (2) @(negedge clk);
        rst = 0;

        // Executer 11 instructions
        repeat (11) @(posedge clk);

        // Attendre les mises a jour des registres
        #1;

        // Registres sources
        check_value(
            dut.u_regfile.registers[1],
            32'd10,
            "x1 = 10"
        );

        check_value(
            dut.u_regfile.registers[2],
            32'd3,
            "x2 = 3"
        );

        // SUB
        check_value(
            dut.u_regfile.registers[3],
            32'd7,
            "SUB"
        );

        // AND
        check_value(
            dut.u_regfile.registers[4],
            32'd2,
            "AND"
        );

        // OR
        check_value(
            dut.u_regfile.registers[5],
            32'd11,
            "OR"
        );

        // XOR
        check_value(
            dut.u_regfile.registers[6],
            32'd9,
            "XOR"
        );

        // SLL
        check_value(
            dut.u_regfile.registers[7],
            32'd80,
            "SLL"
        );

        // SRL
        check_value(
            dut.u_regfile.registers[8],
            32'd1,
            "SRL"
        );

        // SRA
        check_value(
            dut.u_regfile.registers[9],
            32'd1,
            "SRA"
        );

        // SLT
        check_value(
            dut.u_regfile.registers[10],
            32'd0,
            "SLT"
        );

        // SLTU
        check_value(
            dut.u_regfile.registers[11],
            32'd0,
            "SLTU"
        );

        $display("==============================");
        $display("Nombre de tests : %0d", tests);
        $display("Nombre d'erreurs : %0d", errors);

        if (errors == 0)
            $display("TEST ALU INTEGRE REUSSI");
        else
            $display("ECHEC TEST ALU INTEGRE");

        $finish;
    end

endmodule