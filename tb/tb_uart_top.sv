
`timescale 1ns/1ps

module tb_uart_top;

    logic clk = 1'b0;
    logic rst = 1'b1;

    logic tx_start = 1'b0;
    logic [7:0] tx_data = 8'd0;

    wire tx_serial;
    wire tx_busy;
    wire tx_done;

    logic loopback_enable = 1'b1;
    logic injected_rx = 1'b1;
    wire rx_serial;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_error;

    integer errors = 0;
    integer checks = 0;

    integer tx_count = 0;
    integer rx_count = 0;
    integer rx_error_count = 0;

    logic [7:0] received [0:15];

    // Horloge 1 MHz
    always #500 clk = ~clk;

    // Bouclage de TX vers RX
    assign rx_serial =
        loopback_enable ? tx_serial : injected_rx;

    // =====================================
    // INSTANCIATION DE L'IP UART
    // =====================================

    uart_top #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(100000)
    ) dut (
        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_serial(tx_serial),
        .tx_busy(tx_busy),
        .tx_done(tx_done),

        .rx_serial(rx_serial),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // =====================================
    // SURVEILLANCE DES TRANSACTIONS
    // =====================================

    always @(posedge clk) begin
        if (!rst) begin

            if (tx_done)
                tx_count = tx_count + 1;

            if (rx_valid) begin
                if (rx_count < 16)
                    received[rx_count] = rx_data;

                rx_count = rx_count + 1;
            end

            if (rx_error)
                rx_error_count = rx_error_count + 1;

        end
    end

    // =====================================
    // ENVOYER ET VERIFIER UN OCTET
    // =====================================

    task automatic send_and_check(
        input [7:0] value
    );
        integer old_tx;
        integer old_rx;
        integer cycles;

        begin
            old_tx = tx_count;
            old_rx = rx_count;

            // Demander une transmission
            @(negedge clk);
            tx_data = value;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            // Verifier que TX est occupe
            checks = checks + 1;

            if (tx_busy !== 1'b1) begin
                $display("FAIL : tx_busy non actif");
                errors = errors + 1;
            end

            // Attendre transmission et reception
            cycles = 0;

            while (
                (tx_count == old_tx ||
                 rx_count == old_rx) &&
                cycles < 200
            ) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            checks = checks + 1;

            if (cycles >= 200) begin
                $display(
                    "FAIL : timeout UART pour %h",
                    value
                );
                errors = errors + 1;
            end
            else begin

                checks = checks + 1;

                if (received[old_rx] !== value) begin
                    $display(
                        "FAIL UART TX=%h RX=%h",
                        value,
                        received[old_rx]
                    );
                    errors = errors + 1;
                end
                else begin
                    $display(
                        "PASS UART TX=%h RX=%h",
                        value,
                        received[old_rx]
                    );
                end

            end

            repeat (5) @(negedge clk);
        end
    endtask

    // =====================================
    // INJECTION D'UN BIT SERIE
    // =====================================

    task automatic inject_bit(
        input logic bit_value
    );
        begin
            injected_rx = bit_value;
            repeat (10) @(negedge clk);
        end
    endtask

    // =====================================
    // TEST PRINCIPAL
    // =====================================

    initial begin

        // Initialisation
        repeat (4) @(negedge clk);
        rst = 1'b0;

        $display("");
        $display("====================================");
        $display(" ETAPE 27 - VERIFICATION UART");
        $display("====================================");

        // TEST 1 : alternance de bits
        send_and_check(8'h55);

        // TEST 2 : autre motif binaire
        send_and_check(8'hA3);

        // TEST 3 : tous les bits a zero
        send_and_check(8'h00);

        // TEST 4 : tous les bits a un
        send_and_check(8'hFF);

        // =================================
        // VERIFIER LES COMPTEURS
        // =================================

        checks = checks + 1;

        if (tx_count != 4) begin
            $display("FAIL : nombre de TX = %0d", tx_count);
            errors = errors + 1;
        end
        else
            $display("PASS : 4 transmissions");

        checks = checks + 1;

        if (rx_count != 4) begin
            $display("FAIL : nombre de RX = %0d", rx_count);
            errors = errors + 1;
        end
        else
            $display("PASS : 4 receptions");

        checks = checks + 1;

        if (rx_error_count != 0) begin
            $display("FAIL : erreur RX inattendue");
            errors = errors + 1;
        end
        else
            $display("PASS : aucune erreur RX");

        // =================================
        // TEST 5 : ERREUR DE BIT DE STOP
        // =================================

        $display("");
        $display("TEST : ERREUR DE BIT DE STOP");

        loopback_enable = 1'b0;
        injected_rx = 1'b1;

        repeat (5) @(negedge clk);

        // Bit de start
        inject_bit(1'b0);

        // Octet 0x55, LSB en premier
        inject_bit(1'b1);
        inject_bit(1'b0);
        inject_bit(1'b1);
        inject_bit(1'b0);
        inject_bit(1'b1);
        inject_bit(1'b0);
        inject_bit(1'b1);
        inject_bit(1'b0);

        // Bit de stop volontairement incorrect
        inject_bit(1'b0);

        // Repos
        injected_rx = 1'b1;

        repeat (15) @(negedge clk);

        checks = checks + 1;

        if (rx_error_count >= 1)
            $display("PASS : erreur de stop detectee");
        else begin
            $display("FAIL : erreur de stop non detectee");
            errors = errors + 1;
        end

        // =================================
        // BILAN FINAL
        // =================================

        $display("");
        $display("====================================");
        $display(" BILAN ETAPE 27");
        $display("====================================");

        $display("Verifications = %0d", checks);
        $display("TX termines   = %0d", tx_count);
        $display("RX recus      = %0d", rx_count);
        $display("Erreurs RX    = %0d", rx_error_count);
        $display("Erreurs tests = %0d", errors);

        if (errors == 0)
            $display(
                "ETAPE 27 REUSSIE - 0 ERREUR"
            );
        else
            $display(
                "ETAPE 27 ECHOUEE - %0d ERREUR(S)",
                errors
            );

        $display("====================================");

        $stop;
    end

endmodule