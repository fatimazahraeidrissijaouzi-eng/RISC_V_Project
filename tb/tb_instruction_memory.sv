
`timescale 1ns/1ps

module tb_instruction_memory;

    logic [31:0] address;
    logic [31:0] instruction;

    instruction_memory dut (
        .address(address),
        .instruction(instruction)
    );

    task automatic check_instruction(
        input logic [31:0] test_address,
        input logic [31:0] expected
    );
        begin
            address = test_address;
            #10;

            if (instruction !== expected) begin
                $error("ECHEC adresse=%h attendu=%h obtenu=%h",
                       test_address, expected, instruction);
                $fatal(1, "Test Instruction Memory echoue");
            end

            $display("OK adresse=%h instruction=%h",
                     test_address, instruction);
        end
    endtask

    initial begin
        // Lecture des 8 instructions
        check_instruction(32'h00, 32'h00500093);
        check_instruction(32'h04, 32'h00A00113);
        check_instruction(32'h08, 32'h002081B3);
        check_instruction(32'h0C, 32'h00302023);
        check_instruction(32'h10, 32'h00002203);
        check_instruction(32'h14, 32'h004182B3);
        check_instruction(32'h18, 32'h00128313);
        check_instruction(32'h1C, 32'h00000013);

        // Adresse non initialisee : NOP
        check_instruction(32'h20, 32'h00000013);

        // Adresse non alignee : NOP
        check_instruction(32'h02, 32'h00000013);

        // Adresse hors de la memoire : NOP
        check_instruction(32'h400, 32'h00000013);

        $display("TOUS LES TESTS INSTRUCTION MEMORY REUSSIS");
        $finish;
    end

endmodule