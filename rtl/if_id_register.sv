
`timescale 1ns/1ps

module if_id_register (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] instruction_in,

    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

    // =====================================
    // REGISTRE PIPELINE IF/ID
    // =====================================

    always_ff @(posedge clk or posedge rst) begin

        // 1. RESET
        if (rst) begin
            pc_out          <= 32'b0;
            instruction_out <= 32'b0;
        end

        // 2. FLUSH : vider le registre
        else if (flush) begin
            pc_out          <= 32'b0;
            instruction_out <= 32'b0;
        end

        // 3. STALL : conserver les valeurs
        else if (stall) begin
            pc_out          <= pc_out;
            instruction_out <= instruction_out;
        end

        // 4. FONCTIONNEMENT NORMAL
        else begin
            pc_out          <= pc_in;
            instruction_out <= instruction_in;
        end

    end

endmodule