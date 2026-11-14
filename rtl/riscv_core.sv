`timescale 1ns/1ps

module riscv_core (
    input  logic clk,
    input  logic rst,
    output logic [31:0] pc_debug,
    output logic [31:0] instruction_debug
);

    // =====================================
    // SIGNAUX INTERNES
    // =====================================

    logic [31:0] pc_value;
    logic [31:0] instruction;

    logic [6:0] opcode;
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;

    logic [31:0] immediate;
    logic decoder_valid;
    logic control_valid;
    logic instruction_valid;

    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic alu_src;
    logic mem_to_reg;
    logic branch;
    logic jump;

    logic [3:0] alu_control;
    logic [3:0] alu_op;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] alu_b;
    logic [31:0] alu_result;

    logic [31:0] mem_data;
    logic [31:0] writeback_data;

    logic memory_valid;
    logic branch_taken;
    logic [31:0] branch_target;

    logic reg_write_enable;
    logic mem_read_enable;
    logic mem_write_enable;

    // =====================================
    // 1. PROGRAM COUNTER
    // =====================================

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .stall(1'b0),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_out(pc_value)
    );

    // =====================================
    // 2. INSTRUCTION MEMORY
    // =====================================

    instruction_memory u_imem (
        .address(pc_value),
        .instruction(instruction)
    );

    // =====================================
    // 3. INSTRUCTION DECODER
    // =====================================

    instruction_decoder u_decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .immediate(immediate),
        .valid(decoder_valid)
    );

    // =====================================
    // 4. CONTROL UNIT
    // =====================================

    control_unit u_control (
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
        .valid(control_valid)
    );

    assign instruction_valid =
        decoder_valid && control_valid;

    // =====================================
    // 5. REGISTER FILE
    // =====================================

    register_file u_regfile (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write_enable),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(writeback_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // =====================================
    // 6. ADAPTATION DES CODES ALU
    // =====================================

    always_comb begin
        case (alu_control)
            4'd0: alu_op = 4'd0; // ADD
            4'd1: alu_op = 4'd1; // SUB
            4'd2: alu_op = 4'd2; // AND
            4'd3: alu_op = 4'd3; // OR
            4'd4: alu_op = 4'd4; // XOR
            4'd5: alu_op = 4'd8; // SLT
            4'd6: alu_op = 4'd9; // SLTU
            4'd7: alu_op = 4'd5; // SLL
            4'd8: alu_op = 4'd6; // SRL
            4'd9: alu_op = 4'd7; // SRA
            default: alu_op = 4'd0;
        endcase
    end

    // =====================================
    // 7. ALU
    // =====================================

    assign alu_b =
        alu_src ? immediate : rs2_data;

    alu u_alu (
        .a(rs1_data),
        .b(alu_b),
        .alu_op(alu_op),
        .result(alu_result)
    );

    // =====================================
    // 8. DATA MEMORY
    // =====================================

    assign mem_read_enable =
        mem_read && instruction_valid;

    assign mem_write_enable =
        mem_write && instruction_valid;

    data_memory u_dmem (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read_enable),
        .mem_write(mem_write_enable),
        .funct3(funct3),
        .address(alu_result),
        .write_data(rs2_data),
        .read_data(mem_data),
        .valid(memory_valid)
    );

    // =====================================
    // 9. WRITEBACK
    // =====================================

    always_comb begin
        writeback_data = alu_result;

        if (mem_to_reg)
            writeback_data = mem_data;

        // LUI
        if (opcode == 7'b0110111)
            writeback_data = immediate;

        // AUIPC
        if (opcode == 7'b0010111)
            writeback_data = pc_value + immediate;

        // JAL et JALR
        if (jump)
            writeback_data = pc_value + 32'd4;
    end

    assign reg_write_enable =
        reg_write &&
        instruction_valid &&
        memory_valid;

    // =====================================
    // 10. BRANCH ET JUMP
    // =====================================

    always_comb begin

        branch_taken  = 1'b0;
        branch_target = pc_value + immediate;

        if (instruction_valid) begin

            if (branch) begin

                case (funct3)

                    // BEQ
                    3'b000:
                        branch_taken =
                            (rs1_data == rs2_data);

                    // BNE
                    3'b001:
                        branch_taken =
                            (rs1_data != rs2_data);

                    // BLT
                    3'b100:
                        branch_taken =
                            ($signed(rs1_data) <
                             $signed(rs2_data));

                    // BGE
                    3'b101:
                        branch_taken =
                            ($signed(rs1_data) >=
                             $signed(rs2_data));

                    // BLTU
                    3'b110:
                        branch_taken =
                            (rs1_data < rs2_data);

                    // BGEU
                    3'b111:
                        branch_taken =
                            (rs1_data >= rs2_data);

                    default:
                        branch_taken = 1'b0;

                endcase
            end

            // JAL
            if (jump && opcode == 7'b1101111) begin
                branch_taken = 1'b1;
                branch_target = pc_value + immediate;
            end

            // JALR
            if (jump && opcode == 7'b1100111) begin
                branch_taken = 1'b1;
                branch_target =
                    (rs1_data + immediate) & 32'hFFFFFFFE;
            end

        end
    end

    // =====================================
    // 11. SORTIES DEBUG
    // =====================================

    assign pc_debug = pc_value;
    assign instruction_debug = instruction;

endmodule