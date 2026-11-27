`timescale 1ns/1ps

module tb_uvm_top;

    import uvm_pkg::*;
    import axi4lite_pkg::*;

    logic aclk = 0;

    wire uart_tx;
    logic uart_rx = 1'b1;

    always #500 aclk = ~aclk;

    axi4lite_if axi_if(aclk);

    // SVA protocol checker
    axi4lite_assertions sva_checker(axi_if);

    uart_axi4_lite #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(100000)
    ) dut (

        .aclk          (aclk),
        .aresetn       (axi_if.aresetn),

        .s_axi_awaddr  (axi_if.awaddr),
        .s_axi_awvalid (axi_if.awvalid),
        .s_axi_awready (axi_if.awready),

        .s_axi_wdata   (axi_if.wdata),
        .s_axi_wstrb   (axi_if.wstrb),
        .s_axi_wvalid  (axi_if.wvalid),
        .s_axi_wready  (axi_if.wready),

        .s_axi_bresp   (axi_if.bresp),
        .s_axi_bvalid  (axi_if.bvalid),
        .s_axi_bready  (axi_if.bready),

        .s_axi_araddr  (axi_if.araddr),
        .s_axi_arvalid (axi_if.arvalid),
        .s_axi_arready (axi_if.arready),

        .s_axi_rdata   (axi_if.rdata),
        .s_axi_rresp   (axi_if.rresp),
        .s_axi_rvalid  (axi_if.rvalid),
        .s_axi_rready  (axi_if.rready),

        .uart_tx       (uart_tx),
        .uart_rx       (uart_rx)

    );

    initial begin

        axi_if.aresetn = 0;

        repeat (5) @(negedge aclk);

        axi_if.aresetn = 1;

    end

    initial begin

        uvm_config_db#(virtual axi4lite_if)::set(
            null, "*", "vif", axi_if);

        run_test("axi4lite_test");

    end

endmodule