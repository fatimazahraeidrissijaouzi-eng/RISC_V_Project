
`timescale 1ns/1ps

module riscv_axi4_lite_bridge #(
    parameter [31:0] UART_BASE = 32'h10000000
)(
    input  logic        clk,
    input  logic        rst,

    // Interface simple cote CPU
    input  logic        cpu_req,
    input  logic        cpu_write,
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic        cpu_done,
    output logic        cpu_error,

    // AXI4-Lite AW
    output logic [31:0] m_axi_awaddr,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,

    // AXI4-Lite W
    output logic [31:0] m_axi_wdata,
    output logic [3:0]  m_axi_wstrb,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,

    // AXI4-Lite B
    input  logic [1:0]  m_axi_bresp,
    input  logic        m_axi_bvalid,
    output logic        m_axi_bready,

    // AXI4-Lite AR
    output logic [31:0] m_axi_araddr,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,

    // AXI4-Lite R
    input  logic [31:0] m_axi_rdata,
    input  logic [1:0]  m_axi_rresp,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready
);

    typedef enum logic [2:0] {
        IDLE,
        SEND_WRITE,
        WAIT_WRITE,
        SEND_READ,
        WAIT_READ,
        DONE
    } state_t;

    state_t state;

    logic [31:0] addr_reg;
    logic [31:0] data_reg;
    logic aw_sent;
    logic w_sent;

    wire aw_fire = m_axi_awvalid && m_axi_awready;
    wire w_fire  = m_axi_wvalid  && m_axi_wready;
    wire ar_fire = m_axi_arvalid && m_axi_arready;

    assign m_axi_awaddr  = addr_reg;
    assign m_axi_wdata   = data_reg;
    assign m_axi_wstrb   = 4'hF;
    assign m_axi_araddr  = addr_reg;

    assign m_axi_awvalid =
        (state == SEND_WRITE) && !aw_sent;

    assign m_axi_wvalid =
        (state == SEND_WRITE) && !w_sent;

    assign m_axi_bready =
        (state == WAIT_WRITE);

    assign m_axi_arvalid =
        (state == SEND_READ);

    assign m_axi_rready =
        (state == WAIT_READ);

    assign cpu_done = (state == DONE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            addr_reg   <= 0;
            data_reg   <= 0;
            cpu_rdata  <= 0;
            cpu_error  <= 0;
            aw_sent    <= 0;
            w_sent     <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    if (cpu_req) begin
                        addr_reg  <= cpu_addr - UART_BASE;
                        data_reg  <= cpu_wdata;
                        cpu_error <= 0;
                        cpu_rdata <= 0;
                        aw_sent   <= 0;
                        w_sent    <= 0;

                        if (cpu_write)
                            state <= SEND_WRITE;
                        else
                            state <= SEND_READ;
                    end
                end

                SEND_WRITE: begin
                    if (aw_fire)
                        aw_sent <= 1;

                    if (w_fire)
                        w_sent <= 1;

                    if ((aw_sent || aw_fire) &&
                        (w_sent || w_fire))
                        state <= WAIT_WRITE;
                end

                WAIT_WRITE: begin
                    if (m_axi_bvalid) begin
                        cpu_error <= (m_axi_bresp != 2'b00);
                        state <= DONE;
                    end
                end

                SEND_READ: begin
                    if (ar_fire)
                        state <= WAIT_READ;
                end

                WAIT_READ: begin
                    if (m_axi_rvalid) begin
                        cpu_rdata <= m_axi_rdata;
                        cpu_error <= (m_axi_rresp != 2'b00);
                        state <= DONE;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule