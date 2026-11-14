
`timescale 1ns/1ps

module tb_alu_advanced;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0] alu_op;
    logic [31:0] result;

    integer tests = 0;
    integer errors = 0;

    // ALU a tester
    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    // Test automatique
    task automatic check_alu(
        input logic [31:0] val_a,
        input logic [31:0] val_b,
        input logic [3:0] operation,
        input logic [31:0] expected,
        input string test_name
    );
        begin
            a = val_a;
            b = val_b;
            alu_op = operation;

            #10;

            tests = tests + 1;

            if (result === expected)
                $display("OK : %s", test_name);
            else begin
                errors = errors + 1;
                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    test_name, expected, result
                );
            end
        end
    endtask

    initial begin

        $display("==========================");
        $display("TEST AVANCE ALU RISC-V");
        $display("==========================");

        // ADD : 10 + 5 = 15
        check_alu(10, 5, 4'd0, 15, "ADD");

        // SUB : 10 - 5 = 5
        check_alu(10, 5, 4'd1, 5, "SUB");

        // AND : 6 & 3 = 2
        check_alu(6, 3, 4'd2, 2, "AND");

        // OR : 6 | 3 = 7
        check_alu(6, 3, 4'd3, 7, "OR");

        // XOR : 6 ^ 3 = 5
        check_alu(6, 3, 4'd4, 5, "XOR");

        // SLL : 5 << 1 = 10
        check_alu(5, 1, 4'd5, 10, "SLL");

        // SRL : 10 >> 1 = 5
        check_alu(10, 1, 4'd6, 5, "SRL");

        // SRA : -8 >>> 1 = -4
        check_alu(
            32'hFFFFFFF8,
            1,
            4'd7,
            32'hFFFFFFFC,
            "SRA"
        );

        // SLT : -1 < 2 (signed)
        check_alu(
            32'hFFFFFFFF,
            2,
            4'd8,
            1,
            "SLT"
        );

        // SLTU : 1 < 2 (unsigned)
        check_alu(1, 2, 4'd9, 1, "SLTU");

        $display("==========================");
        $display("Nombre de tests : %0d", tests);
        $display("Nombre d'erreurs : %0d", errors);

        if (errors == 0)
            $display("TOUS LES TESTS ALU REUSSIS");
        else
            $fatal(1, "ECHEC DES TESTS ALU");

        $finish;
    end

endmodule