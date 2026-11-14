
`timescale 1ns/1ps

module tb_control_unit;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic reg_write, mem_read, mem_write;
    logic alu_src, mem_to_reg, branch, jump;
    logic [3:0] alu_control;
    logic valid;

    integer tests = 0;

    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_control(alu_control),
        .valid(valid)
    );

    task automatic check_control(
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7,
        input logic [8:0] expected,
        input string name
    );
        logic [8:0] actual;
        begin
            opcode = op;
            funct3 = f3;
            funct7 = f7;
            #10;

            actual = {
                valid,
                reg_write,
                mem_read,
                mem_write,
                alu_src,
                mem_to_reg,
                branch,
                jump,
                1'b0
            };

            // Comparer les signaux de commande
            if (actual !== expected)
                $fatal(1,
                    "ECHEC %s : attendu=%b obtenu=%b",
                    name, expected, actual);

            tests = tests + 1;
            $display("OK %s", name);
        end
    endtask

    task automatic check_alu(
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7,
        input logic [3:0] expected_alu,
        input string name
    );
        begin
            opcode = op;
            funct3 = f3;
            funct7 = f7;
            #10;

            if (alu_control !== expected_alu ||
                valid !== 1'b1)
                $fatal(1, "ECHEC ALU %s", name);

            tests = tests + 1;
            $display("OK ALU %s", name);
        end
    endtask

    initial begin
        opcode = 0;
        funct3 = 0;
        funct7 = 0;
        #10;

        // Encodage expected :
        // {valid, reg_write, mem_read, mem_write,
        //  alu_src, mem_to_reg, branch, jump, 0}

        check_control(7'h33, 0, 0,
                      9'b110000000, "ADD");

        check_control(7'h13, 0, 0,
                      9'b110010000, "ADDI");

        check_control(7'h03, 2, 0,
                      9'b111011000, "LW");

        check_control(7'h23, 2, 0,
                      9'b100110000, "SW");

        check_control(7'h63, 0, 0,
                      9'b100000100, "BEQ");

        check_control(7'h6F, 0, 0,
                      9'b110000010, "JAL");

        check_control(7'h67, 0, 0,
                      9'b110010010, "JALR");

        check_control(7'h37, 0, 0,
                      9'b110010000, "LUI");

        check_control(7'h17, 0, 0,
                      9'b110010000, "AUIPC");

        check_control(7'h7F, 0, 0,
                      9'b000000000, "INVALID OPCODE");

        // Verification des operations ALU
        check_alu(7'h33, 0, 7'b0100000,
                  4'd1, "SUB");

        check_alu(7'h33, 7, 0,
                  4'd2, "AND");

        check_alu(7'h33, 6, 0,
                  4'd3, "OR");

        check_alu(7'h33, 4, 0,
                  4'd4, "XOR");

        check_alu(7'h33, 2, 0,
                  4'd5, "SLT");

        check_alu(7'h33, 3, 0,
                  4'd6, "SLTU");

        check_alu(7'h33, 1, 0,
                  4'd7, "SLL");

        check_alu(7'h33, 5, 0,
                  4'd8, "SRL");

        check_alu(7'h33, 5, 7'b0100000,
                  4'd9, "SRA");

        $display("--------------------------------");
        $display("TOUS LES TESTS CONTROL UNIT REUSSIS");
        $display("Nombre de tests : %0d", tests);
        $display("--------------------------------");

        $finish;
    end

endmodule