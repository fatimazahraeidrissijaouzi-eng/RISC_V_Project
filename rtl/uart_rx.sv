
`timescale 1ns/1ps

module uart_rx #(
    parameter integer CLK_FREQ  = 1000000,
    parameter integer BAUD_RATE = 100000
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx_serial,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT = CLKS_PER_BIT / 2;
    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT > 1) ? $clog2(CLKS_PER_BIT + 1) : 1;

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    rx_state_t state;

    logic [COUNTER_WIDTH-1:0] counter;
    logic [2:0] bit_index;
    logic [7:0] data_reg;

    // Synchronisation de l'entree serie
    logic rx_meta;
    logic rx_sync;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx_serial;
            rx_sync <= rx_meta;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= RX_IDLE;
            counter   <= '0;
            bit_index <= 3'd0;
            data_reg  <= 8'd0;
            rx_data   <= 8'd0;
            rx_valid  <= 1'b0;
            rx_error  <= 1'b0;
        end
        else begin
            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)

                RX_IDLE: begin
                    counter <= '0;

                    if (!rx_sync) begin
                        state <= RX_START;
                    end
                end

                RX_START: begin
                    if (counter == HALF_BIT - 1) begin
                        counter <= '0;

                        if (!rx_sync) begin
                            bit_index <= 3'd0;
                            state <= RX_DATA;
                        end
                        else begin
                            state <= RX_IDLE;
                        end
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                RX_DATA: begin
                    if (counter == CLKS_PER_BIT - 1) begin
                        counter <= '0;

                        data_reg[bit_index] <= rx_sync;

                        if (bit_index == 3'd7) begin
                            state <= RX_STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                RX_STOP: begin
                    if (counter == CLKS_PER_BIT - 1) begin
                        counter <= '0;

                        if (rx_sync) begin
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;
                        end
                        else begin
                            rx_error <= 1'b1;
                        end

                        state <= RX_IDLE;
                    end
                    else begin
                        counter <= counter + 1'b1;
                    end
                end

                default: begin
                    state <= RX_IDLE;
                end

            endcase
        end
    end

endmodule