`timescale 1ns/1ps

module uart_top #(
    parameter integer CLK_FREQ  = 1000000,
    parameter integer BAUD_RATE = 100000
)(
    input  logic       clk,
    input  logic       rst,

    // Interface transmission UART
    input  logic       tx_start,
    input  logic [7:0] tx_data,

    output logic       tx_serial,
    output logic       tx_busy,
    output logic       tx_done,

    // Interface reception UART
    input  logic       rx_serial,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    // =====================================
    // SIGNAL INTERNE
    // =====================================

    logic baud_tick;

    // =====================================
    // GENERATEUR DE BAUD RATE
    // =====================================

    uart_baud_generator #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk(clk),
        .rst(rst),
        .enable(tx_busy),
        .baud_tick(baud_tick)
    );

    // =====================================
    // MODULE UART TX
    // =====================================

    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_serial(tx_serial),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // =====================================
    // MODULE UART RX
    // =====================================

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk),
        .rst(rst),
        .rx_serial(rx_serial),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

endmodule