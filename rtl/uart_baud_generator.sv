
`timescale 1ns/1ps

module uart_baud_generator #(
    parameter integer CLK_FREQ  = 1000000,
    parameter integer BAUD_RATE = 100000
)(
    input  logic clk,
    input  logic rst,
    input  logic enable,
    output logic baud_tick
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer WIDTH =
        (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT) : 1;

    logic [WIDTH-1:0] counter;

    // Impulsion active pendant le dernier
    // cycle de chaque periode UART.
    assign baud_tick =
        enable && (counter == CLKS_PER_BIT - 1);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            counter <= '0;
        else if (!enable)
            counter <= '0;
        else if (baud_tick)
            counter <= '0;
        else
            counter <= counter + 1'b1;
    end

endmodule