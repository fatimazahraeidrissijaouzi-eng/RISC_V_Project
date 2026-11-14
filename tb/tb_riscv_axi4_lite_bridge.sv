
`timescale 1ns/1ps

module tb_riscv_axi4_lite_bridge;

    logic clk = 0;
    logic rst = 1;

    logic cpu_req = 0;
    logic cpu_write = 0;
    logic [31:0] cpu_addr = 0;
    logic [31:0] cpu_wdata = 0;

    wire [31:0] cpu_rdata;
    wire cpu_done;
    wire cpu_error;

    // AXI4-Lite : AW
    wire [31:0] awaddr;
    wire awvalid, awready;

    // AXI4-Lite : W
    wire [31:0] wdata;
    wire [3:0] wstrb;
    wire wvalid, wready;

    // AXI4-Lite : B
    wire [1:0] bresp;
    wire bvalid, bready;

    // AXI4-Lite : AR
    wire [31:0] araddr;
    wire arvalid, arready;

    // AXI4-Lite : R
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid, rready;

    // UART
    wire uart_tx;
    wire uart_rx;

    // Compteurs
    integer checks = 0;
    integer errors = 0;
    integer i;

    logic [31:0] value;
    logic err;
    logic received;

    // Adresses des registres UART
    localparam [31:0] BASE    = 32'h10000000;
    localparam [31:0] TX_DATA = BASE + 32'h00;
    localparam [31:0] RX_DATA = BASE + 32'h04;
    localparam [31:0] STATUS  = BASE + 32'h08;
    localparam [31:0] CONTROL = BASE + 32'h0C;

    // Horloge 1 MHz
    always #500 clk = ~clk;

    // Loopback UART
    assign uart_rx = uart_tx;

    // ==========================================
    // PONT AXI4-LITE
    // ==========================================

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

    // ==========================================
    // UART AXI4-LITE EXISTANT
    // ==========================================

    uart_axi4_lite #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(100000)
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

    // ==========================================
    // TASK : VERIFICATION
    // ==========================================

    task automatic check(
        input [31:0] actual,
        input [31:0] expected,
        input string message
    );
        begin
            checks = checks + 1;

            if (actual !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL %s : obtenu=%h attendu=%h",
                    message, actual, expected
                );
            end
            else begin
                $display("PASS %s", message);
            end
        end
    endtask

    // ==========================================
    // TASK : ECRITURE CPU
    // ==========================================

    task automatic cpu_store(
        input [31:0] address,
        input [31:0] data,
        output logic error_result
    );
        integer timeout;

        begin
            @(negedge clk);

            cpu_addr  = address;
            cpu_wdata = data;
            cpu_write = 1'b1;
            cpu_req   = 1'b1;

            @(negedge clk);
            cpu_req = 1'b0;

            timeout = 0;

            while (!cpu_done && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (!cpu_done) begin
                errors = errors + 1;
                $display("FAIL : timeout CPU STORE");
                error_result = 1'b1;
            end
            else begin
                error_result = cpu_error;
            end

            @(negedge clk);
        end
    endtask

    // ==========================================
    // TASK : LECTURE CPU
    // ==========================================

    task automatic cpu_load(
        input [31:0] address,
        output logic [31:0] data,
        output logic error_result
    );
        integer timeout;

        begin
            @(negedge clk);

            cpu_addr  = address;
            cpu_write = 1'b0;
            cpu_req   = 1'b1;

            @(negedge clk);
            cpu_req = 1'b0;

            timeout = 0;

            while (!cpu_done && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (!cpu_done) begin
                errors = errors + 1;
                $display("FAIL : timeout CPU LOAD");
                data = 32'd0;
                error_result = 1'b1;
            end
            else begin
                data = cpu_rdata;
                error_result = cpu_error;
            end

            @(negedge clk);
        end
    endtask

    // ==========================================
    // PROGRAMME PRINCIPAL
    // ==========================================

    initial begin

        repeat (5) @(negedge clk);
        rst = 0;

        $display("");
        $display("================================");
        $display(" ETAPE 29 - TEST DU PONT AXI");
        $display("================================");

        // TEST 1 : CONTROL APRES RESET
        cpu_load(CONTROL, value, err);
        check(value, 32'h1, "CONTROL = 1");
        check({31'd0, err}, 0, "Lecture OKAY");

        // TEST 2 : DESACTIVER UART
        cpu_store(CONTROL, 0, err);
        check({31'd0, err}, 0, "Ecriture CONTROL");

        cpu_load(CONTROL, value, err);
        check(value, 0, "UART desactive");

        // TEST 3 : REACTIVER UART
        cpu_store(CONTROL, 1, err);
        check({31'd0, err}, 0, "UART reactive");

        cpu_load(CONTROL, value, err);
        check(value, 1, "CONTROL = 1");

        // TEST 4 : TRANSMISSION UART
        cpu_store(TX_DATA, 32'h55, err);
        check({31'd0, err}, 0, "TX 55 accepte");

        // Attendre la reception UART
        received = 0;

        for (i = 0; i < 150; i = i + 1) begin
            if (!received) begin
                cpu_load(STATUS, value, err);

                if (value[1])
                    received = 1;
            end
        end

        check({31'd0, received}, 1,
              "RX_PENDING detecte");

        cpu_load(RX_DATA, value, err);
        check(value, 32'h55, "RX_DATA = 55");

        // TEST 5 : EFFACEMENT RX_PENDING
        cpu_store(STATUS, 32'h2, err);
        check({31'd0, err}, 0,
              "Ecriture STATUS W1C");

        cpu_load(STATUS, value, err);
        check({31'd0, value[1]}, 0,
              "RX_PENDING efface");

        // TEST 6 : ADRESSE INVALIDE
        cpu_load(BASE + 32'h20, value, err);
        check({31'd0, err}, 1,
              "Adresse invalide detectee");

        // ==========================================
        // BILAN FINAL
        // ==========================================

        $display("");
        $display("================================");
        $display(" BILAN TEST PONT AXI");
        $display(" Verifications = %0d", checks);
        $display(" Erreurs       = %0d", errors);

        if (errors == 0)
            $display("PONT AXI VALIDE - 0 ERREUR");
        else
            $display(
                "PONT AXI ECHEC - %0d ERREURS",
                errors
            );

        $display("================================");

        $stop;

    end

endmodule