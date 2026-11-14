
`timescale 1ns/1ps

module tb_riscv_verification;

    logic clk = 0;
    logic rst = 1;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;

    integer tests = 0;
    integer errors = 0;
    integer cycles = 0;

    riscv_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug)
    );

    // Horloge : periode de 10 ns
    always #5 clk = ~clk;

    task automatic check_value(
        input [31:0] actual,
        input [31:0] expected,
        input string test_name
    );
        begin
            tests = tests + 1;

            if (actual === expected)
                $display("OK : %s", test_name);
            else begin
                errors = errors + 1;
                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    test_name, expected, actual
                );
            end
        end
    endtask

    initial begin

        $display("==============================");
        $display("ETAPE 16 : VERIFICATION RISC-V");
        $display("==============================");

        // Initialisation
        rst = 1;
        #2;

        check_value(pc_debug, 32'd0,
                    "PC pendant reset");

        check_value(dut.u_regfile.registers[0],
                    32'd0, "x0 pendant reset");

        // Sortie du reset
        @(negedge clk);
        rst = 0;

        // Execution du programme existant
        repeat (20) begin
            @(negedge clk);
            cycles = cycles + 1;

            // Verification permanente de x0
            check_value(
                dut.u_regfile.registers[0],
                32'd0,
                "Registre x0"
            );

            // PC aligne sur 4 octets
            tests = tests + 1;

            if (pc_debug[1:0] === 2'b00)
                $display("OK : PC aligne");
            else begin
                errors = errors + 1;
                $display("ERREUR : PC non aligne");
            end
        end

        // Test de reset apres execution
        rst = 1;
        #2;

        check_value(pc_debug, 32'd0,
                    "PC apres reset");

        check_value(dut.u_regfile.registers[0],
                    32'd0, "x0 apres reset");

        $display("==============================");
        $display("TESTS  : %0d", tests);
        $display("ERREURS: %0d", errors);

        if (errors == 0)
            $display("ETAPE 16 : TESTS REUSSIS");
        else
            $display("ETAPE 16 : ECHEC");

        $display("==============================");

        $finish;
    end

endmodule