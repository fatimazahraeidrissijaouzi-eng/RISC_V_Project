
`timescale 1ns/1ps

module uart_axi4_lite #(
    parameter integer CLK_FREQ  = 1000000,
    parameter integer BAUD_RATE = 100000
)(
    input  logic        aclk,
    input  logic        aresetn,

    // AXI4-Lite : adresse d'ecriture
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // AXI4-Lite : donnees d'ecriture
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // AXI4-Lite : reponse d'ecriture
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // AXI4-Lite : adresse de lecture
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI4-Lite : donnees de lecture
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // UART physique
    output logic        uart_tx,
    input  logic        uart_rx
);

    localparam [1:0]
        RESP_OKAY   = 2'b00,
        RESP_SLVERR = 2'b10,
        RESP_DECERR = 2'b11;

    localparam [7:0]
        ADDR_TX_DATA = 8'h00,
        ADDR_RX_DATA = 8'h04,
        ADDR_STATUS  = 8'h08,
        ADDR_CONTROL = 8'h0C;

    logic uart_rst;
    logic uart_enable;

    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;
    logic       tx_done;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_error;

    logic [7:0] last_rx_data;
    logic       rx_pending;
    logic       error_pending;

    // Tampons independants AW et W
    logic        aw_pending;
    logic [31:0] awaddr_reg;

    logic        w_pending;
    logic [31:0] wdata_reg;
    logic [3:0]  wstrb_reg;

    logic aw_accept;
    logic w_accept;
    logic write_commit;
    logic read_accept;

    logic clear_rx_pending;
    logic clear_error_pending;

    assign uart_rst = ~aresetn;

    // Une seule transaction d'ecriture a la fois.
    // AW et W peuvent arriver a des cycles differents.
    assign s_axi_awready = !aw_pending && !s_axi_bvalid;
    assign s_axi_wready  = !w_pending  && !s_axi_bvalid;

    assign aw_accept = s_axi_awvalid && s_axi_awready;
    assign w_accept  = s_axi_wvalid  && s_axi_wready;

    assign write_commit =
        aw_pending && w_pending && !s_axi_bvalid;

    // Une seule lecture en attente.
    assign s_axi_arready = !s_axi_rvalid;
    assign read_accept = s_axi_arvalid && s_axi_arready;

    // Effacement des indicateurs par ecriture W1C.
    assign clear_rx_pending =
        write_commit &&
        (awaddr_reg[7:0] == ADDR_STATUS) &&
        (awaddr_reg[31:8] == 0) &&
        wstrb_reg[0] &&
        wdata_reg[1];

    assign clear_error_pending =
        write_commit &&
        (awaddr_reg[7:0] == ADDR_STATUS) &&
        (awaddr_reg[31:8] == 0) &&
        wstrb_reg[0] &&
        wdata_reg[2];

    // ==========================================
    // IP UART EXISTANTE : AUCUNE MODIFICATION
    // ==========================================

    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart (
        .clk(aclk),
        .rst(uart_rst),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_serial(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),

        .rx_serial(uart_rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // ==========================================
    // CAPTURE DES EVENEMENTS RX
    // ==========================================

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            last_rx_data  <= 8'd0;
            rx_pending    <= 1'b0;
            error_pending <= 1'b0;
        end
        else begin
            if (clear_rx_pending)
                rx_pending <= 1'b0;

            if (clear_error_pending)
                error_pending <= 1'b0;

            // Priorite a un nouvel evenement.
            if (rx_valid) begin
                last_rx_data <= rx_data;
                rx_pending   <= 1'b1;
            end

            if (rx_error)
                error_pending <= 1'b1;
        end
    end

    // ==========================================
    // CANAUX AXI : ECRITURE
    // ==========================================

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            aw_pending   <= 1'b0;
            awaddr_reg   <= 32'd0;
            w_pending    <= 1'b0;
            wdata_reg    <= 32'd0;
            wstrb_reg    <= 4'd0;

            s_axi_bresp  <= RESP_OKAY;
            s_axi_bvalid <= 1'b0;

            uart_enable  <= 1'b1;
            tx_start     <= 1'b0;
            tx_data      <= 8'd0;
        end
        else begin
            // Impulsion d'un cycle
            tx_start <= 1'b0;

            if (aw_accept) begin
                awaddr_reg <= s_axi_awaddr;
                aw_pending <= 1'b1;
            end

            if (w_accept) begin
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
                w_pending <= 1'b1;
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (write_commit) begin
                aw_pending   <= 1'b0;
                w_pending    <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= RESP_OKAY;

                // Adresses alignees sur 32 bits
                if (awaddr_reg[31:8] != 0 ||
                    awaddr_reg[1:0] != 0) begin
                    s_axi_bresp <= RESP_DECERR;
                end
                else begin
                    case (awaddr_reg[7:0])

                        ADDR_TX_DATA: begin
                            if (wstrb_reg[0]) begin
                                if (uart_enable &&
                                    !tx_busy &&
                                    !tx_start) begin
                                    tx_data  <= wdata_reg[7:0];
                                    tx_start <= 1'b1;
                                end
                                else
                                    s_axi_bresp <= RESP_SLVERR;
                            end
                        end

                        ADDR_RX_DATA: begin
                            // Registre en lecture seule
                            s_axi_bresp <= RESP_SLVERR;
                        end

                        ADDR_STATUS: begin
                            // W1C traite par les signaux
                            // clear_rx_pending et
                            // clear_error_pending.
                        end

                        ADDR_CONTROL: begin
                            if (wstrb_reg[0])
                                uart_enable <= wdata_reg[0];
                        end

                        default: begin
                            s_axi_bresp <= RESP_DECERR;
                        end

                    endcase
                end
            end
        end
    end

    // ==========================================
    // CANAUX AXI : LECTURE
    // ==========================================

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rdata  <= 32'd0;
            s_axi_rresp  <= RESP_OKAY;
            s_axi_rvalid <= 1'b0;
        end
        else begin
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (read_accept) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= 32'd0;
                s_axi_rresp  <= RESP_OKAY;

                if (s_axi_araddr[31:8] != 0 ||
                    s_axi_araddr[1:0] != 0) begin
                    s_axi_rresp <= RESP_DECERR;
                end
                else begin
                    case (s_axi_araddr[7:0])

                        ADDR_TX_DATA:
                            s_axi_rdata <= {24'd0, tx_data};

                        ADDR_RX_DATA:
                            s_axi_rdata <= {24'd0, last_rx_data};

                        ADDR_STATUS:
                            s_axi_rdata <= {
                                29'd0,
                                error_pending,
                                rx_pending,
                                tx_busy
                            };

                        ADDR_CONTROL:
                            s_axi_rdata <= {31'd0, uart_enable};

                        default:
                            s_axi_rresp <= RESP_DECERR;

                    endcase
                end
            end
        end
    end

endmodule