
`timescale 1ns/1ps

module tb_alu;

    logic [31:0] a, b;
    logic [3:0] alu_op;
    logic [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    task automatic check_alu(
        input logic [31:0] test_a,
        input logic [31:0] test_b,
        input logic [3:0] test_op,
        input logic [31:0] expected
    );
        begin
            a = test_a;
            b = test_b;
            alu_op = test_op;
            #10;

            if (result !== expected) begin
                $error("ECHEC op=%0d attendu=%h obtenu=%h",
                       test_op, expected, result);
                $fatal(1, "Test ALU echoue");
            end

            $display("OK op=%0d resultat=%h",
                     test_op, result);
        end
    endtask

    initial begin
        check_alu(10, 5, 4'd0, 15);  // ADD
        check_alu(10, 5, 4'd1, 5);   // SUB
        check_alu(10, 5, 4'd2, 0);   // AND
        check_alu(10, 5, 4'd3, 15);  // OR
        check_alu(10, 5, 4'd4, 15);  // XOR

        check_alu(5, 1, 4'd5, 10);   // SLL
        check_alu(8, 1, 4'd6, 4);    // SRL

        check_alu(32'hFFFFFFF8, 1,
                  4'd7, 32'hFFFFFFFC); // SRA

        check_alu(32'hFFFFFFFB, 3,
                  4'd8, 1); // SLT (-5 < 3)

        check_alu(5, 10, 4'd9, 1);   // SLTU

        $display("TOUS LES TESTS ALU REUSSIS");
        $finish;
    end

endmodule