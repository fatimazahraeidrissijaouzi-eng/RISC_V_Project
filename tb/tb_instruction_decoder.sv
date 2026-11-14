
`timescale 1ns/1ps

module tb_instruction_decoder;

    logic [31:0] instruction;

    logic [6:0]  opcode;
    logic [4:0]  rs1, rs2, rd;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] immediate;
    logic        valid;

    integer tests_passed = 0;

    instruction_decoder dut (
        .instruction(instruction),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .immediate(immediate),
        .valid(valid)
    );

    task automatic check_decode(
        input logic [31:0] instr,
        input logic [6:0]  exp_opcode,
        input logic [4:0]  exp_rs1,
        input logic [4:0]  exp_rs2,
        input logic [4:0]  exp_rd,
        input logic [31:0] exp_imm,
        input logic        exp_valid
    );
        begin
            instruction = instr;
            #10;

            if ((opcode    !== exp_opcode) ||
                (rs1       !== exp_rs1) ||
                (rs2       !== exp_rs2) ||
                (rd        !== exp_rd) ||
                (immediate !== exp_imm) ||
                (valid     !== exp_valid)) begin

                $display("ECHEC instruction=%h", instr);
                $display("opcode=%h rs1=%0d rs2=%0d rd=%0d",
                         opcode, rs1, rs2, rd);
                $display("immediate=%h valid=%b",
                         immediate, valid);
                $fatal(1, "Erreur de decodage");
            end

            tests_passed = tests_passed + 1;

            $display("OK instr=%h opcode=%h imm=%h valid=%b",
                     instr, opcode, immediate, valid);
        end
    endtask

    initial begin

        // ADDI x1, x0, 5
        check_decode(32'h00500093,
                     7'h13, 0, 5, 1, 5, 1);

        // ADDI x2, x0, 10
        check_decode(32'h00A00113,
                     7'h13, 0, 10, 2, 10, 1);

        // ADD x3, x1, x2
        check_decode(32'h002081B3,
                     7'h33, 1, 2, 3, 0, 1);

        // SW x3, 0(x0)
        check_decode(32'h00302023,
                     7'h23, 0, 3, 0, 0, 1);

        // LW x4, 0(x0)
        check_decode(32'h00002203,
                     7'h03, 0, 0, 4, 0, 1);

        // ADD x5, x3, x4
        check_decode(32'h004182B3,
                     7'h33, 3, 4, 5, 0, 1);

        // ADDI x6, x5, 1
        check_decode(32'h00128313,
                     7'h13, 5, 1, 6, 1, 1);

        // NOP = ADDI x0, x0, 0
        check_decode(32'h00000013,
                     7'h13, 0, 0, 0, 0, 1);

        // ADDI x1, x0, -1
        check_decode(32'hFFF00093,
                     7'h13, 0, 31, 1,
                     32'hFFFFFFFF, 1);

        // BEQ x0, x0, 8
        check_decode(32'h00000463,
                     7'h63, 0, 0, 8, 8, 1);

        // LUI x1, 0x12345
        check_decode(32'h123450B7,
                     7'h37, 8, 3, 1,
                     32'h12345000, 1);

        // JAL x1, 8
        check_decode(32'h008000EF,
                     7'h6F, 0, 8, 1, 8, 1);

        // Opcode inconnu
        check_decode(32'h00000000,
                     7'h00, 0, 0, 0, 0, 0);

        // Instruction R-type non prise en charge
        check_decode(32'h020000B3,
                     7'h33, 0, 0, 1, 0, 0);

        $display("------------------------------------");
        $display("TOUS LES TESTS DECODER REUSSIS");
        $display("Nombre de tests : %0d", tests_passed);
        $display("------------------------------------");

        $finish;
    end

endmodule