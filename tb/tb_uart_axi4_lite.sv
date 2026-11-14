
`timescale 1ns/1ps

module tb_uart_axi4_lite;

    // ==========================================
    // HORLOGE ET RESET
    // ==========================================

    logic clk = 1'b0;
    logic rstn = 1'b0;

    // ==========================================
    // AXI4-LITE : WRITE ADDRESS
    // ==========================================

    logic [31:0] awaddr = 0;
    logic awvalid = 0;
    wire awready;

    // ==========================================
    // AXI4-LITE : WRITE DATA
    // ==========================================

    logic [31:0] wdata = 0;
    logic [3:0] wstrb = 0;
    logic wvalid = 0;
    wire wready;

    // ==========================================
    // AXI4-LITE : WRITE RESPONSE
    // ==========================================

    wire [1:0] bresp;
    wire bvalid;
    logic bready = 0;

    // ==========================================
    // AXI4-LITE : READ ADDRESS
    // ==========================================

    logic [31:0] araddr = 0;
    logic arvalid = 0;
    wire arready;

    // ==========================================
    // AXI4-LITE : READ DATA
    // ==========================================

    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    logic rready = 0;

    // ==========================================
    // UART
    // ==========================================

    wire uart_tx;
    wire uart_rx;

    logic loopback = 1'b1;
    logic injected_rx = 1'b1;

    assign uart_rx = loopback ? uart_tx : injected_rx;

    // ==========================================
    // COMPTEURS DE VERIFICATION
    // ==========================================

    integer errors = 0;
    integer checks = 0;

    logic [31:0] read_value;
    logic [1:0] response;

    // Horloge 1 MHz : periode de 1000 ns
    always #500 clk = ~clk;

    // ==========================================
    // INSTANCIATION DU DUT
    // ==========================================

    uart_axi4_lite #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(100000)
    ) dut (
        .aclk(clk),
        .aresetn(rstn),

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
    // TASK : VERIFIER UNE VALEUR
    // ==========================================

    task automatic check_value(
        input [31:0] actual,
        input [31:0] expected,
        input [8*60-1:0] message
    );
        begin
            checks = checks + 1;

            if (actual !== expected) begin
                errors = errors + 1;

                $display(
                    "FAIL %0s : obtenu=%h attendu=%h",
                    message, actual, expected
                );
            end
            else begin
                $display(
                    "PASS %0s = %h",
                    message, actual
                );
            end
        end
    endtask

    // ==========================================
    // TASK : ECRITURE AXI4-LITE
    // ==========================================

    task automatic axi_write(
        input [31:0] address,
        input [31:0] value,
        input [3:0] strobe,
        output [1:0] result
    );

        bit aw_done;
        bit w_done;
        integer count;

        begin

            @(negedge clk);

            awaddr  = address;
            awvalid = 1'b1;

            wdata   = value;
            wstrb   = strobe;
            wvalid  = 1'b1;

            bready = 1'b0;

            aw_done = 0;
            w_done  = 0;
            count   = 0;

            // AW et W sont independants

            while (!(aw_done && w_done) &&
                   count < 50) begin

                @(posedge clk);

                if (awvalid && awready)
                    aw_done = 1;

                if (wvalid && wready)
                    w_done = 1;

                @(negedge clk);

                if (aw_done)
                    awvalid = 0;

                if (w_done)
                    wvalid = 0;

                count = count + 1;

            end

            if (!(aw_done && w_done)) begin

                errors = errors + 1;
                result = 2'b11;

                $display(
                    "FAIL : timeout AXI AW/W"
                );

            end
            else begin

                count = 0;

                while (!bvalid && count < 50) begin
                    @(negedge clk);
                    count = count + 1;
                end

                if (!bvalid) begin

                    errors = errors + 1;
                    result = 2'b11;

                    $display(
                        "FAIL : timeout AXI BVALID"
                    );

                end
                else begin

                    result = bresp;

                    bready = 1'b1;

                    @(negedge clk);

                    bready = 1'b0;

                end

            end

        end
    endtask

    // ==========================================
    // TASK : LECTURE AXI4-LITE
    // ==========================================

    task automatic axi_read(
        input [31:0] address,
        output [31:0] value,
        output [1:0] result
    );

        integer count;
        bit accepted;

        begin

            @(negedge clk);

            araddr  = address;
            arvalid = 1'b1;

            rready = 1'b0;

            accepted = 0;
            count = 0;

            while (!accepted && count < 50) begin

                @(posedge clk);

                if (arvalid && arready)
                    accepted = 1;

                @(negedge clk);

                count = count + 1;

            end

            arvalid = 1'b0;

            if (!accepted) begin

                errors = errors + 1;
                value = 0;
                result = 2'b11;

                $display(
                    "FAIL : timeout AXI ARREADY"
                );

            end
            else begin

                count = 0;

                while (!rvalid && count < 50) begin
                    @(negedge clk);
                    count = count + 1;
                end

                if (!rvalid) begin

                    errors = errors + 1;
                    value = 0;
                    result = 2'b11;

                    $display(
                        "FAIL : timeout AXI RVALID"
                    );

                end
                else begin

                    value = rdata;
                    result = rresp;

                    rready = 1'b1;

                    @(negedge clk);

                    rready = 1'b0;

                end

            end

        end
    endtask

    // ==========================================
    // TASK : ATTENDRE UNE RECEPTION UART
    // ==========================================

    task automatic wait_rx_pending;

        integer count;

        logic [31:0] status_value;
        logic [1:0] status_resp;

        begin

            count = 0;
            status_value = 0;

            while (!status_value[1] &&
                   count < 150) begin

                axi_read(
                    32'h00000008,
                    status_value,
                    status_resp
                );

                count = count + 1;

            end

            checks = checks + 1;

            if (!status_value[1]) begin

                errors = errors + 1;

                $display(
                    "FAIL : timeout reception UART"
                );

            end
            else begin

                $display(
                    "PASS : RX_PENDING detecte"
                );

            end

        end
    endtask

    // ==========================================
    // TEST PRINCIPAL
    // ==========================================

    initial begin

        repeat (5) @(negedge clk);

        rstn = 1'b1;

        $display("");
        $display("====================================");
        $display(" ETAPE 28 - UART AXI4-LITE");
        $display("====================================");

        // ==================================
        // TEST 1 : CONTROL APRES RESET
        // ==================================

        axi_read(
            32'h0000000C,
            read_value,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "CONTROL reponse OKAY"
        );

        check_value(
            read_value,
            32'h00000001,
            "CONTROL actif"
        );

        // ==================================
        // TEST 2 : DESACTIVER UART
        // ==================================

        axi_write(
            32'h0000000C,
            32'h00000000,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "Ecriture CONTROL"
        );

        axi_read(
            32'h0000000C,
            read_value,
            response
        );

        check_value(
            read_value,
            32'h00000000,
            "CONTROL desactive"
        );

        // ==================================
        // TEST 3 : TX REFUSE SI DESACTIVE
        // ==================================

        axi_write(
            32'h00000000,
            32'h00000055,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd2,
            "TX refuse si desactive"
        );

        // ==================================
        // TEST 4 : REACTIVER UART
        // ==================================

        axi_write(
            32'h0000000C,
            32'h00000001,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "UART reactive"
        );

        // ==================================
        // TEST 5 : TRANSMISSION 0x55
        // ==================================

        axi_write(
            32'h00000000,
            32'h00000055,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "TX 55 accepte"
        );

        wait_rx_pending();

        axi_read(
            32'h00000004,
            read_value,
            response
        );

        check_value(
            read_value,
            32'h00000055,
            "RX_DATA 55"
        );

        // ==================================
        // TEST 6 : RX_PENDING
        // ==================================

        axi_read(
            32'h00000008,
            read_value,
            response
        );

        checks = checks + 1;

        if (read_value[1] !== 1'b1) begin

            errors = errors + 1;

            $display(
                "FAIL : RX_PENDING absent"
            );

        end
        else begin

            $display(
                "PASS : RX_PENDING actif"
            );

        end

        // ==================================
        // TEST 7 : EFFACEMENT W1C
        // ==================================

        axi_write(
            32'h00000008,
            32'h00000002,
            4'h1,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "STATUS W1C ecriture"
        );

        axi_read(
            32'h00000008,
            read_value,
            response
        );

        checks = checks + 1;

        if (read_value[1] !== 1'b0) begin

            errors = errors + 1;

            $display(
                "FAIL : RX_PENDING non efface"
            );

        end
        else begin

            $display(
                "PASS : RX_PENDING efface"
            );

        end

        // ==================================
        // TEST 8 : TRANSMISSION 0xA3
        // ==================================

        axi_write(
            32'h00000000,
            32'h000000A3,
            4'h1,
            response
        );

        check_value(
            {30'd0, response},
            32'd0,
            "TX A3 accepte"
        );

        wait_rx_pending();

        axi_read(
            32'h00000004,
            read_value,
            response
        );

        check_value(
            read_value,
            32'h000000A3,
            "RX_DATA A3"
        );

        // ==================================
        // TEST 9 : RX_DATA LECTURE SEULE
        // ==================================

        axi_write(
            32'h00000004,
            32'h00000012,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd2,
            "RX_DATA lecture seule"
        );

        // ==================================
        // TEST 10 : ADRESSE INVALIDE
        // ==================================

        axi_read(
            32'h00000020,
            read_value,
            response
        );

        check_value(
            {30'd0, response},
            32'd3,
            "Adresse invalide DECERR"
        );

        // ==================================
        // TEST 11 : ADRESSE NON ALIGNEE
        // ==================================

        axi_write(
            32'h00000003,
            32'h00000012,
            4'hF,
            response
        );

        check_value(
            {30'd0, response},
            32'd3,
            "Adresse non alignee"
        );

        // ==================================
        // TEST 12 : DERNIER OCTET CONSERVE
        // ==================================

        axi_read(
            32'h00000004,
            read_value,
            response
        );

        check_value(
            read_value,
            32'h000000A3,
            "RX_DATA conserve"
        );

        // ==================================
        // BILAN FINAL
        // ==================================

        $display("");
        $display("====================================");
        $display(" BILAN ETAPE 28");
        $display("====================================");

        $display(
            "Verifications = %0d",
            checks
        );

        $display(
            "Erreurs       = %0d",
            errors
        );

        if (errors == 0) begin

            $display(
                "ETAPE 28 REUSSIE - 0 ERREUR"
            );

        end
        else begin

            $display(
                "ETAPE 28 ECHOUEE - %0d ERREURS",
                errors
            );

        end

        $display("====================================");

        $stop;

    end

endmodule