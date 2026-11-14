
`timescale 1ns/1ps

module riscv_pipeline_uart_core (
    input  logic clk,
    input  logic rst,

    output logic [31:0] pc_debug,
    output logic [31:0] instruction_debug,
    output logic stall_debug,
    output logic forwarding_debug,
    output logic flush_debug,
    output logic mmio_stall_debug,

    output logic        cpu_req,
    output logic        cpu_write,
    output logic [31:0] cpu_addr,
    output logic [31:0] cpu_wdata,
    input  logic [31:0] cpu_rdata,
    input  logic        cpu_done,
    input  logic        cpu_error
);

    localparam [6:0]
        OP_R      = 7'b0110011,
        OP_I      = 7'b0010011,
        OP_LOAD   = 7'b0000011,
        OP_STORE  = 7'b0100011,
        OP_BRANCH = 7'b1100011,
        OP_LUI    = 7'b0110111,
        OP_AUIPC  = 7'b0010111,
        OP_JAL    = 7'b1101111,
        OP_JALR   = 7'b1100111;

    // ==========================================
    // 1. SIGNAUX GENERAUX
    // ==========================================

    logic [31:0] pc_f, instruction_f;
    logic [31:0] pc_d, instruction_d;

    logic pc_write;
    logic if_id_write;
    logic hazard_bubble;

    logic redirect_ex;
    logic redirect_active;
    logic [31:0] target_ex;

    // ==========================================
    // 2. INTERFACE UART MMIO
    // ==========================================

    logic mmio_access;
    logic mmio_issued;
    logic mmio_complete;
    logic mmio_error;
    logic mmio_wait;

    logic [31:0] mmio_read_result;

    // ==========================================
    // 3. ETAGE IF
    // ==========================================

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .stall(!pc_write || mmio_wait),
        .branch_taken(redirect_active),
        .branch_target(target_ex),
        .pc_out(pc_f)
    );

    instruction_memory u_imem (
        .address(pc_f),
        .instruction(instruction_f)
    );

    assign pc_debug = pc_f;
    assign instruction_debug = instruction_f;

    if_id_register u_if_id (
        .clk(clk),
        .rst(rst),
        .stall(!if_id_write || mmio_wait),
        .flush(redirect_active),
        .pc_in(pc_f),
        .instruction_in(instruction_f),
        .pc_out(pc_d),
        .instruction_out(instruction_d)
    );

    // ==========================================
    // 4. ETAGE ID
    // ==========================================

    logic [6:0] opcode_d;
    logic [6:0] funct7_d;
    logic [2:0] funct3_d;

    logic [4:0] rs1_d;
    logic [4:0] rs2_d;
    logic [4:0] rd_d;

    logic [31:0] imm_d;

    logic decoder_valid_d;
    logic control_valid_d;
    logic valid_d;

    logic reg_write_d;
    logic mem_read_d;
    logic mem_write_d;
    logic alu_src_d;
    logic mem_to_reg_d;
    logic branch_d;
    logic jump_d;

    logic [3:0] alu_control_d;

    logic uses_rs1_d;
    logic uses_rs2_d;

    logic [4:0] hazard_rs1_d;
    logic [4:0] hazard_rs2_d;

    instruction_decoder u_decoder (
        .instruction(instruction_d),
        .opcode(opcode_d),
        .rs1(rs1_d),
        .rs2(rs2_d),
        .rd(rd_d),
        .funct3(funct3_d),
        .funct7(funct7_d),
        .immediate(imm_d),
        .valid(decoder_valid_d)
    );

    control_unit u_control (
        .opcode(opcode_d),
        .funct3(funct3_d),
        .funct7(funct7_d),
        .reg_write(reg_write_d),
        .mem_read(mem_read_d),
        .mem_write(mem_write_d),
        .alu_src(alu_src_d),
        .mem_to_reg(mem_to_reg_d),
        .branch(branch_d),
        .jump(jump_d),
        .alu_control(alu_control_d),
        .valid(control_valid_d)
    );

    assign valid_d =
        decoder_valid_d && control_valid_d;

    assign uses_rs1_d =
        valid_d &&
        (
            opcode_d == OP_R      ||
            opcode_d == OP_I      ||
            opcode_d == OP_LOAD   ||
            opcode_d == OP_STORE  ||
            opcode_d == OP_BRANCH ||
            opcode_d == OP_JALR
        );

    assign uses_rs2_d =
        valid_d &&
        (
            opcode_d == OP_R      ||
            opcode_d == OP_STORE  ||
            opcode_d == OP_BRANCH
        );

    assign hazard_rs1_d =
        uses_rs1_d ? rs1_d : 5'd0;

    assign hazard_rs2_d =
        uses_rs2_d ? rs2_d : 5'd0;

    // ==========================================
    // 5. WRITEBACK
    // ==========================================

    logic [31:0] pc_w;
    logic [31:0] alu_w;
    logic [31:0] mem_w;
    logic [31:0] wb_data;

    logic [4:0] rd_w;

    logic reg_write_w;
    logic mem_to_reg_w;
    logic wb_we;

    assign wb_data =
        mem_to_reg_w ? mem_w : alu_w;

    assign wb_we =
        reg_write_w && (rd_w != 5'd0);

    // ==========================================
    // 6. REGISTER FILE
    // ==========================================

    logic [31:0] rs1_raw_d;
    logic [31:0] rs2_raw_d;
    logic [31:0] rs1_data_d;
    logic [31:0] rs2_data_d;

    register_file u_regfile (
        .clk(clk),
        .rst(rst),
        .reg_write(wb_we),
        .rs1_addr(rs1_d),
        .rs2_addr(rs2_d),
        .rd_addr(rd_w),
        .rd_data(wb_data),
        .rs1_data(rs1_raw_d),
        .rs2_data(rs2_raw_d)
    );

    assign rs1_data_d =
        (
            wb_we &&
            rs1_d != 5'd0 &&
            rs1_d == rd_w
        )
        ? wb_data : rs1_raw_d;

    assign rs2_data_d =
        (
            wb_we &&
            rs2_d != 5'd0 &&
            rs2_d == rd_w
        )
        ? wb_data : rs2_raw_d;

    // ==========================================
    // 7. ETAGE ID/EX
    // ==========================================

    logic [31:0] pc_e;
    logic [31:0] rs1_e;
    logic [31:0] rs2_e;
    logic [31:0] imm_e;

    logic [4:0] rs1_idx_e;
    logic [4:0] rs2_idx_e;
    logic [4:0] rd_e;

    logic reg_write_e;
    logic mem_read_e;
    logic mem_write_e;
    logic alu_src_e;
    logic mem_to_reg_e;
    logic branch_e;
    logic jump_e;

    logic [3:0] alu_control_e;

    id_ex_register u_id_ex (
        .clk(clk),
        .rst(rst),
        .stall(mmio_wait),
        .flush(
            redirect_active ||
            (hazard_bubble && !mmio_wait)
        ),

        .pc_in(pc_d),
        .rs1_data_in(rs1_data_d),
        .rs2_data_in(rs2_data_d),
        .immediate_in(imm_d),

        .rs1_in(rs1_d),
        .rs2_in(rs2_d),
        .rd_in(rd_d),

        .reg_write_in(reg_write_d && valid_d),
        .mem_read_in(mem_read_d && valid_d),
        .mem_write_in(mem_write_d && valid_d),
        .alu_src_in(alu_src_d),
        .mem_to_reg_in(mem_to_reg_d && valid_d),
        .branch_in(branch_d && valid_d),
        .jump_in(jump_d && valid_d),
        .alu_control_in(alu_control_d),

        .pc_out(pc_e),
        .rs1_data_out(rs1_e),
        .rs2_data_out(rs2_e),
        .immediate_out(imm_e),

        .rs1_out(rs1_idx_e),
        .rs2_out(rs2_idx_e),
        .rd_out(rd_e),

        .reg_write_out(reg_write_e),
        .mem_read_out(mem_read_e),
        .mem_write_out(mem_write_e),
        .alu_src_out(alu_src_e),
        .mem_to_reg_out(mem_to_reg_e),
        .branch_out(branch_e),
        .jump_out(jump_e),
        .alu_control_out(alu_control_e)
    );

    logic [6:0] opcode_e;
    logic [2:0] funct3_e;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            opcode_e <= 7'd0;
            funct3_e <= 3'd0;
        end
        else if (mmio_wait) begin
            // Conserver les valeurs
        end
        else if (redirect_active || hazard_bubble) begin
            opcode_e <= 7'd0;
            funct3_e <= 3'd0;
        end
        else begin
            opcode_e <= valid_d ? opcode_d : 7'd0;
            funct3_e <= funct3_d;
        end
    end

    // ==========================================
    // 8. HAZARD DETECTION
    // ==========================================

    hazard_detection_unit u_hazard (
        .id_ex_rd(rd_e),
        .id_ex_mem_read(mem_read_e),
        .if_id_rs1(hazard_rs1_d),
        .if_id_rs2(hazard_rs2_d),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_mux_sel(hazard_bubble)
    );

    assign stall_debug = hazard_bubble;
    assign flush_debug = redirect_active;

    // ==========================================
    // 9. SIGNAUX EX/MEM
    // ==========================================

    logic [31:0] pc_m;
    logic [31:0] alu_m;
    logic [31:0] store_m;

    logic [4:0] rd_m;

    logic reg_write_m;
    logic mem_read_m;
    logic mem_write_m;
    logic mem_to_reg_m;

    // ==========================================
    // 10. DETECTION DES ACCES UART
    // ==========================================

    // Zone UART : 0x10000000 - 0x100000FF

    assign mmio_access =
        (mem_read_m || mem_write_m) &&
        (alu_m[31:8] == 24'h100000);

    assign mmio_wait =
        mmio_access && !mmio_complete;

    assign mmio_stall_debug = mmio_wait;

    assign cpu_req =
        mmio_access &&
        !mmio_issued &&
        !mmio_complete;

    assign cpu_write = mem_write_m;
    assign cpu_addr  = alu_m;
    assign cpu_wdata = store_m;

    assign redirect_active =
        redirect_ex && !mmio_wait;

    // ==========================================
    // 11. GESTION DE LA TRANSACTION AXI
    // ==========================================

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mmio_issued <= 1'b0;
            mmio_complete <= 1'b0;
            mmio_error <= 1'b0;
            mmio_read_result <= 32'd0;
        end
        else begin

            if (cpu_req)
                mmio_issued <= 1'b1;

            if (cpu_done && mmio_issued) begin
                mmio_complete <= 1'b1;
                mmio_error <= cpu_error;
                mmio_read_result <= cpu_rdata;
            end

            if (!mmio_wait) begin
                mmio_issued <= 1'b0;
                mmio_complete <= 1'b0;
            end

        end
    end

    // ==========================================
    // 12. FORWARDING UNIT
    // ==========================================

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    logic [31:0] operand_a_ex;
    logic [31:0] operand_b_ex;

    logic [31:0] alu_b_ex;
    logic [31:0] alu_result_ex;
    logic [31:0] result_ex;

    logic [3:0] alu_op_ex;

    forwarding_unit u_forward (
        .id_ex_rs1(rs1_idx_e),
        .id_ex_rs2(rs2_idx_e),

        .ex_mem_rd(rd_m),
        .ex_mem_reg_write(
            reg_write_m && !mem_to_reg_m
        ),

        .mem_wb_rd(rd_w),
        .mem_wb_reg_write(wb_we),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    always_comb begin
        case (forward_a)
            2'b10:
                operand_a_ex = alu_m;

            2'b01:
                operand_a_ex = wb_data;

            default:
                operand_a_ex = rs1_e;
        endcase

        case (forward_b)
            2'b10:
                operand_b_ex = alu_m;

            2'b01:
                operand_b_ex = wb_data;

            default:
                operand_b_ex = rs2_e;
        endcase
    end

    assign forwarding_debug =
        (forward_a != 2'b00) ||
        (forward_b != 2'b00);

    // ==========================================
    // 13. ALU
    // ==========================================

    assign alu_b_ex =
        alu_src_e ? imm_e : operand_b_ex;

    always_comb begin
        case (alu_control_e)
            4'd0: alu_op_ex = 4'd0;
            4'd1: alu_op_ex = 4'd1;
            4'd2: alu_op_ex = 4'd2;
            4'd3: alu_op_ex = 4'd3;
            4'd4: alu_op_ex = 4'd4;
            4'd5: alu_op_ex = 4'd8;
            4'd6: alu_op_ex = 4'd9;
            4'd7: alu_op_ex = 4'd5;
            4'd8: alu_op_ex = 4'd6;
            4'd9: alu_op_ex = 4'd7;
            default: alu_op_ex = 4'd0;
        endcase
    end

    alu u_alu (
        .a(operand_a_ex),
        .b(alu_b_ex),
        .alu_op(alu_op_ex),
        .result(alu_result_ex)
    );

    always_comb begin
        result_ex = alu_result_ex;

        if (opcode_e == OP_LUI)
            result_ex = imm_e;

        else if (opcode_e == OP_AUIPC)
            result_ex = pc_e + imm_e;

        else if (jump_e)
            result_ex = pc_e + 32'd4;
    end

    // ==========================================
    // 14. BRANCH ET JUMP
    // ==========================================

    always_comb begin
        redirect_ex = 1'b0;
        target_ex = pc_e + imm_e;

        if (branch_e) begin
            case (funct3_e)

                3'b000:
                    redirect_ex =
                        (operand_a_ex == operand_b_ex);

                3'b001:
                    redirect_ex =
                        (operand_a_ex != operand_b_ex);

                3'b100:
                    redirect_ex =
                        ($signed(operand_a_ex) <
                         $signed(operand_b_ex));

                3'b101:
                    redirect_ex =
                        ($signed(operand_a_ex) >=
                         $signed(operand_b_ex));

                3'b110:
                    redirect_ex =
                        (operand_a_ex < operand_b_ex);

                3'b111:
                    redirect_ex =
                        (operand_a_ex >= operand_b_ex);

                default:
                    redirect_ex = 1'b0;

            endcase
        end

        if (jump_e) begin
            redirect_ex = 1'b1;

            if (opcode_e == OP_JALR)
                target_ex =
                    (operand_a_ex + imm_e) &
                    32'hFFFFFFFE;
        end
    end

    // ==========================================
    // 15. REGISTRE EX/MEM
    // ==========================================

    ex_mem_register u_ex_mem (
        .clk(clk),
        .rst(rst),
        .stall(mmio_wait),
        .flush(1'b0),

        .pc_in(pc_e),
        .alu_result_in(result_ex),
        .rs2_data_in(operand_b_ex),
        .rd_in(rd_e),

        .reg_write_in(reg_write_e),
        .mem_read_in(mem_read_e),
        .mem_write_in(mem_write_e),
        .mem_to_reg_in(mem_to_reg_e),

        .pc_out(pc_m),
        .alu_result_out(alu_m),
        .rs2_data_out(store_m),
        .rd_out(rd_m),

        .reg_write_out(reg_write_m),
        .mem_read_out(mem_read_m),
        .mem_write_out(mem_write_m),
        .mem_to_reg_out(mem_to_reg_m)
    );

    logic [2:0] funct3_m;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            funct3_m <= 3'd0;

        else if (!mmio_wait)
            funct3_m <= funct3_e;
    end

    // ==========================================
    // 16. DATA MEMORY
    // ==========================================

    logic [31:0] mem_data_m;
    logic memory_valid_m;

    logic [31:0] selected_mem_data;
    logic selected_mem_valid;

    assign selected_mem_data =
        mmio_access ?
        mmio_read_result :
        mem_data_m;

    assign selected_mem_valid =
        mmio_access ?
        (mmio_complete && !mmio_error) :
        memory_valid_m;

    data_memory u_dmem (
        .clk(clk),
        .rst(rst),

        .mem_read(
            mem_read_m && !mmio_access
        ),

        .mem_write(
            mem_write_m && !mmio_access
        ),

        .funct3(funct3_m),
        .address(alu_m),
        .write_data(store_m),

        .read_data(mem_data_m),
        .valid(memory_valid_m)
    );

    // ==========================================
    // 17. REGISTRE MEM/WB
    // ==========================================

    mem_wb_register u_mem_wb (
        .clk(clk),
        .rst(rst),
        .stall(mmio_wait),
        .flush(1'b0),

        .pc_in(pc_m),
        .alu_result_in(alu_m),
        .mem_data_in(selected_mem_data),
        .rd_in(rd_m),

        .reg_write_in(
            reg_write_m &&
            (!mem_read_m || selected_mem_valid)
        ),

        .mem_to_reg_in(mem_to_reg_m),

        .pc_out(pc_w),
        .alu_result_out(alu_w),
        .mem_data_out(mem_w),
        .rd_out(rd_w),

        .reg_write_out(reg_write_w),
        .mem_to_reg_out(mem_to_reg_w)
    );

endmodule