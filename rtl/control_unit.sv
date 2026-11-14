`timescale 1ns/1ps

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic alu_src,
    output logic mem_to_reg,
    output logic branch,
    output logic jump,
    output logic [3:0] alu_control,
    output logic valid
);

    // Codes ALU utilises dans riscv_core
    localparam logic [3:0]
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_AND  = 4'd2,
        ALU_OR   = 4'd3,
        ALU_XOR  = 4'd4,
        ALU_SLT  = 4'd5,
        ALU_SLTU = 4'd6,
        ALU_SLL  = 4'd7,
        ALU_SRL  = 4'd8,
        ALU_SRA  = 4'd9;

    always_comb begin

        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        mem_to_reg  = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        alu_control = ALU_ADD;
        valid       = 1'b0;

        case (opcode)

            // =================================
            // R-TYPE
            // =================================
            7'b0110011: begin

                reg_write = 1'b1;

                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = ALU_ADD;
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = ALU_SUB;
                            valid = 1'b1;
                        end
                    end

                    3'b001: begin
                        alu_control = ALU_SLL;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b010: begin
                        alu_control = ALU_SLT;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b011: begin
                        alu_control = ALU_SLTU;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b100: begin
                        alu_control = ALU_XOR;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = ALU_SRL;
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = ALU_SRA;
                            valid = 1'b1;
                        end
                    end

                    3'b110: begin
                        alu_control = ALU_OR;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b111: begin
                        alu_control = ALU_AND;
                        valid = (funct7 == 7'b0000000);
                    end

                    default: valid = 1'b0;

                endcase
            end

            // =================================
            // I-TYPE ALU
            // =================================
            7'b0010011: begin

                reg_write = 1'b1;
                alu_src   = 1'b1;

                case (funct3)

                    3'b000: begin
                        alu_control = ALU_ADD;
                        valid = 1'b1;
                    end

                    3'b010: begin
                        alu_control = ALU_SLT;
                        valid = 1'b1;
                    end

                    3'b011: begin
                        alu_control = ALU_SLTU;
                        valid = 1'b1;
                    end

                    3'b100: begin
                        alu_control = ALU_XOR;
                        valid = 1'b1;
                    end

                    3'b110: begin
                        alu_control = ALU_OR;
                        valid = 1'b1;
                    end

                    3'b111: begin
                        alu_control = ALU_AND;
                        valid = 1'b1;
                    end

                    3'b001: begin
                        alu_control = ALU_SLL;
                        valid = (funct7 == 7'b0000000);
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = ALU_SRL;
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = ALU_SRA;
                            valid = 1'b1;
                        end
                    end

                    default: valid = 1'b0;

                endcase
            end

            // =================================
            // LOAD
            // =================================
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b010) ||
                    (funct3 == 3'b100) ||
                    (funct3 == 3'b101);
            end

            // =================================
            // STORE
            // =================================
            7'b0100011: begin
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_control = ALU_ADD;

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b010);
            end

            // =================================
            // BRANCH
            // =================================
            7'b1100011: begin
                branch = 1'b1;
                alu_control = ALU_SUB;

                valid =
                    (funct3 == 3'b000) ||
                    (funct3 == 3'b001) ||
                    (funct3 == 3'b100) ||
                    (funct3 == 3'b101) ||
                    (funct3 == 3'b110) ||
                    (funct3 == 3'b111);
            end

            // =================================
            // LUI
            // =================================
            7'b0110111: begin
                reg_write = 1'b1;
                valid = 1'b1;
            end

            // =================================
            // AUIPC
            // =================================
            7'b0010111: begin
                reg_write = 1'b1;
                valid = 1'b1;
            end

            // =================================
            // JAL
            // =================================
            7'b1101111: begin
                jump = 1'b1;
                reg_write = 1'b1;
                valid = 1'b1;
            end

            // =================================
            // JALR
            // =================================
            7'b1100111: begin
                jump = 1'b1;
                reg_write = 1'b1;
                alu_src = 1'b1;
                valid = (funct3 == 3'b000);
            end

            default: begin
                valid = 1'b0;
            end

        endcase
    end

endmodule