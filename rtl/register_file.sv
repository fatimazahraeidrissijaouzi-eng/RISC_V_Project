
module register_file (
    input  logic        clk,
    input  logic        rst,
    input  logic        reg_write,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] registers [0:31];

    integer i;

    // Ecriture synchrone et reset
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write && rd_addr != 5'd0) begin
            registers[rd_addr] <= rd_data;
        end
    end

    // Lecture asynchrone
    assign rs1_data = (rs1_addr == 5'd0)
                      ? 32'b0 : registers[rs1_addr];

    assign rs2_data = (rs2_addr == 5'd0)
                      ? 32'b0 : registers[rs2_addr];

endmodule