
`timescale 1ns/1ps

module ex_mem_register (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,

    // =====================================
    // ENTREES : ETAGE EX
    // =====================================

    input  logic [31:0] pc_in,
    input  logic [31:0] alu_result_in,
    input  logic [31:0] rs2_data_in,

    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        mem_to_reg_in,

    // =====================================
    // SORTIES : ETAGE MEM
    // =====================================

    output logic [31:0] pc_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] rs2_data_out,

    output logic [4:0]  rd_out,

    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        mem_to_reg_out
);

    // =====================================
    // REGISTRE PIPELINE EX/MEM
    // =====================================

    always_ff @(posedge clk or posedge rst) begin

        // =================================
        // 1. RESET
        // =================================

        if (rst) begin

            pc_out         <= 32'b0;
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;

            rd_out         <= 5'b0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;

        end

        // =================================
        // 2. FLUSH
        // =================================

        else if (flush) begin

            pc_out         <= 32'b0;
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;

            rd_out         <= 5'b0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;

        end

        // =================================
        // 3. STALL
        // =================================

        else if (stall) begin

            // Les sorties conservent
            // leurs valeurs precedentes.

        end

        // =================================
        // 4. TRANSFERT NORMAL
        // =================================

        else begin

            pc_out         <= pc_in;
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;

            rd_out         <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;

        end

    end

endmodule