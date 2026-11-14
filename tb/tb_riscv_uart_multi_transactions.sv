
`timescale 1ns/1ps

module tb_riscv_uart_multi_transactions;

    logic clk = 0;
    logic rst = 1;

    wire uart_tx;
    wire uart_rx;

    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire stall_debug;
    wire forwarding_debug;
    wire flush_debug;
    wire mmio_stall_debug;

    integer checks = 0;
    integer errors = 0;
    integer stall_cycles = 0;
    integer tx_starts = 0;

    logic previous_tx = 1'b1;

    always #500 clk = ~clk;

    assign uart_rx = uart_tx;

    riscv_uart_soc #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(100000)
    ) dut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .stall_debug(stall_debug),
        .forwarding_debug(forwarding_debug),
        .flush_debug(flush_debug),
        .mmio_stall_debug(mmio_stall_debug)
    );

    function automatic [31:0] enc_lui(
        input [4:0] rd,
        input [19:0] imm
    );
        enc_lui = {imm, rd, 7'b0110111};
    endfunction

    function automatic [31:0] enc_addi(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        enc_addi = {imm, rs1, 3'b000,
                    rd, 7'b0010011};
    endfunction

    function automatic [31:0] enc_sw(
        input [4:0] rs2, rs1,
        input [11:0] imm
    );
        enc_sw = {imm[11:5], rs2, rs1,
                  3'b010, imm[4:0],
                  7'b0100011};
    endfunction

    function automatic [31:0] enc_lw(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        enc_lw = {imm, rs1, 3'b010,
                  rd, 7'b0000011};
    endfunction

    function automatic [31:0] enc_andi(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        enc_andi = {imm, rs1, 3'b111,
                    rd, 7'b0010011};
    endfunction

    function automatic [31:0] enc_beq(
        input [4:0] rs1, rs2,
        input [12:0] imm
    );
        enc_beq = {
            imm[12], imm[10:5],
            rs2, rs1, 3'b000,
            imm[4:1], imm[11],
            7'b1100011
        };
    endfunction

    function automatic [31:0] enc_jal(
        input [4:0] rd,
        input [20:0] imm
    );
        enc_jal = {
            imm[20], imm[10:1],
            imm[11], imm[19:12],
            rd, 7'b1101111
        };
    endfunction

    task automatic check(
        input logic condition,
        input string description
    );
        checks = checks + 1;

        if (condition === 1'b1)
            $display("PASS: %s", description);
        else begin
            errors = errors + 1;
            $display("FAIL: %s", description);
        end
    endtask

    always @(posedge clk) begin
        if (!rst) begin
            if (mmio_stall_debug)
                stall_cycles = stall_cycles + 1;

            if (previous_tx && !uart_tx)
                tx_starts = tx_starts + 1;

            previous_tx = uart_tx;
        end
    end

    initial begin

        #2;

        for (integer i = 0; i < 256; i++)
            dut.cpu.u_imem.memory[i] = 32'h00000013;

        // Adresse UART dans x1
        dut.cpu.u_imem.memory[0] =
            enc_lui(5'd1, 20'h10000);

        // Premier caractere 0x55
        dut.cpu.u_imem.memory[1] =
            enc_addi(5'd2, 5'd0, 12'h055);

        dut.cpu.u_imem.memory[2] =
            enc_sw(5'd2, 5'd1, 12'd0);

        // Attendre RX_PENDING
        dut.cpu.u_imem.memory[3] =
            enc_lw(5'd3, 5'd1, 12'd8);

        dut.cpu.u_imem.memory[4] =
            enc_andi(5'd4, 5'd3, 12'd2);

        dut.cpu.u_imem.memory[5] =
            enc_beq(5'd4, 5'd0, 13'h1FF8);

        // Lire RX_DATA
        dut.cpu.u_imem.memory[6] =
            enc_lw(5'd10, 5'd1, 12'd4);

        // Effacer RX_PENDING (W1C)
        dut.cpu.u_imem.memory[7] =
            enc_addi(5'd8, 5'd0, 12'd2);

        dut.cpu.u_imem.memory[8] =
            enc_sw(5'd8, 5'd1, 12'd8);

        // Deuxieme caractere 0xA5
        dut.cpu.u_imem.memory[9] =
            enc_addi(5'd2, 5'd0, 12'h0A5);

        dut.cpu.u_imem.memory[10] =
            enc_sw(5'd2, 5'd1, 12'd0);

        dut.cpu.u_imem.memory[11] =
            enc_lw(5'd3, 5'd1, 12'd8);

        dut.cpu.u_imem.memory[12] =
            enc_andi(5'd4, 5'd3, 12'd2);

        dut.cpu.u_imem.memory[13] =
            enc_beq(5'd4, 5'd0, 13'h1FF8);

        dut.cpu.u_imem.memory[14] =
            enc_lw(5'd11, 5'd1, 12'd4);

        // Effacer RX_PENDING
        dut.cpu.u_imem.memory[15] =
            enc_sw(5'd8, 5'd1, 12'd8);

        // Troisieme caractere 0x3C
        dut.cpu.u_imem.memory[16] =
            enc_addi(5'd2, 5'd0, 12'h03C);

        dut.cpu.u_imem.memory[17] =
            enc_sw(5'd2, 5'd1, 12'd0);

        dut.cpu.u_imem.memory[18] =
            enc_lw(5'd3, 5'd1, 12'd8);

        dut.cpu.u_imem.memory[19] =
            enc_andi(5'd4, 5'd3, 12'd2);

        dut.cpu.u_imem.memory[20] =
            enc_beq(5'd4, 5'd0, 13'h1FF8);

        dut.cpu.u_imem.memory[21] =
            enc_lw(5'd12, 5'd1, 12'd4);

        // Boucle finale
        dut.cpu.u_imem.memory[22] =
            enc_jal(5'd0, 21'd0);

        repeat (5) @(negedge clk);
        rst = 0;

        // Maximum 1 ms
        repeat (1000) @(negedge clk);

        $display("");
        $display("==================================");
        $display("TEST MULTI-TRANSACTIONS UART");
        $display("==================================");

        check(
            dut.cpu.u_regfile.registers[1] == 32'h10000000,
            "Adresse UART correcte"
        );

        check(
            dut.cpu.u_regfile.registers[10] == 32'h55,
            "Reception 0x55"
        );

        check(
            dut.cpu.u_regfile.registers[11] == 32'hA5,
            "Reception 0xA5"
        );

        check(
            dut.cpu.u_regfile.registers[12] == 32'h3C,
            "Reception 0x3C"
        );

        check(
            stall_cycles > 0,
            "Stalls AXI detectes"
        );

        check(
            tx_starts >= 3,
            "Activite UART detectee"
        );

        $display("");
        $display("Verifications = %0d", checks);
        $display("Erreurs = %0d", errors);

        if (errors == 0)
            $display("MULTI UART : TESTS REUSSIS");
        else
            $display("MULTI UART : TESTS ECHOUES");

        $stop;
    end

endmodule