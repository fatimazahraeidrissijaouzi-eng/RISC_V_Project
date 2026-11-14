
`timescale 1ns/1ps

module riscv_uart_soc #(
    parameter integer CLK_FREQ = 1000000,
    parameter integer BAUD_RATE = 100000
)(
    input  logic clk,
    input  logic rst,
    input  logic uart_rx,
    output logic uart_tx,
    output logic [31:0] pc_debug,
    output logic [31:0] instruction_debug,
    output logic stall_debug,
    output logic forwarding_debug,
    output logic flush_debug,
    output logic mmio_stall_debug
);

    wire cpu_req, cpu_write, cpu_done, cpu_error;
    wire [31:0] cpu_addr, cpu_wdata, cpu_rdata;

    wire [31:0] awaddr, wdata, araddr, rdata;
    wire [3:0] wstrb;

    wire awvalid, awready, wvalid, wready;
    wire bvalid, bready;
    wire arvalid, arready, rvalid, rready;
    wire [1:0] bresp, rresp;

    // Processeur RISC-V
    riscv_pipeline_uart_core cpu (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .stall_debug(stall_debug),
        .forwarding_debug(forwarding_debug),
        .flush_debug(flush_debug),
        .mmio_stall_debug(mmio_stall_debug),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_done(cpu_done),
        .cpu_error(cpu_error)
    );

    // Pont CPU vers AXI4-Lite
    riscv_axi4_lite_bridge bridge (
        .clk(clk),
        .rst(rst),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_done(cpu_done),
        .cpu_error(cpu_error),

        .m_axi_awaddr(awaddr),
        .m_axi_awvalid(awvalid),
        .m_axi_awready(awready),

        .m_axi_wdata(wdata),
        .m_axi_wstrb(wstrb),
        .m_axi_wvalid(wvalid),
        .m_axi_wready(wready),

        .m_axi_bresp(bresp),
        .m_axi_bvalid(bvalid),
        .m_axi_bready(bready),

        .m_axi_araddr(araddr),
        .m_axi_arvalid(arvalid),
        .m_axi_arready(arready),

        .m_axi_rdata(rdata),
        .m_axi_rresp(rresp),
        .m_axi_rvalid(rvalid),
        .m_axi_rready(rready)
    );

    // Peripherique UART AXI4-Lite
    uart_axi4_lite #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart (
        .aclk(clk),
        .aresetn(~rst),

        .s_axi_awaddr(awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        .s_axi_araddr(araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),

        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

endmodule