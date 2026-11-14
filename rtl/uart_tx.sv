
`timescale 1ns/1ps

module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       baud_tick,
    input  logic       tx_start,
    input  logic [7:0] tx_data,

    output logic       tx_serial,
    output logic       tx_busy,
    output logic       tx_done
);

    // =====================================
    // ETATS DE LA MACHINE UART TX
    // =====================================

    localparam [1:0]
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3;

    logic [1:0] state;

    logic [7:0] data_reg;
    logic [2:0] bit_index;

    // =====================================
    // TRANSMISSION UART
    // =====================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            state     <= IDLE;
            data_reg  <= 8'd0;
            bit_index <= 3'd0;
            tx_serial <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
        end

        else begin

            tx_done <= 1'b0;

            case (state)

                // -------------------------
                // ETAT IDLE
                // -------------------------
                IDLE: begin

                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;

                    if (tx_start) begin
                        data_reg  <= tx_data;
                        bit_index <= 3'd0;

                        tx_serial <= 1'b0;
                        tx_busy   <= 1'b1;

                        state <= START;
                    end

                end

                // -------------------------
                // BIT DE START
                // -------------------------
                START: begin

                    if (baud_tick) begin
                        tx_serial <= data_reg[0];
                        state <= DATA;
                    end

                end

                // -------------------------
                // 8 BITS DE DONNEES
                // -------------------------
                DATA: begin

                    if (baud_tick) begin

                        if (bit_index == 3'd7) begin
                            tx_serial <= 1'b1;
                            state <= STOP;
                        end

                        else begin
                            bit_index <= bit_index + 1'b1;

                            tx_serial <=
                                data_reg[bit_index + 1'b1];
                        end

                    end

                end

                // -------------------------
                // BIT DE STOP
                // -------------------------
                STOP: begin

                    if (baud_tick) begin
                        tx_serial <= 1'b1;
                        tx_busy   <= 1'b0;
                        tx_done   <= 1'b1;

                        state <= IDLE;
                    end

                end

                // -------------------------
                // ETAT PAR DEFAUT
                // -------------------------
                default: begin
                    state     <= IDLE;
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                end

            endcase

        end

    end

endmodule