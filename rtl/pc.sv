
module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        branch_taken,
    input  logic [31:0] branch_target,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h00000000;

        else if (branch_taken)
            pc_out <= branch_target;

        else if (!stall)
            pc_out <= pc_out + 32'd4;
    end

endmodule