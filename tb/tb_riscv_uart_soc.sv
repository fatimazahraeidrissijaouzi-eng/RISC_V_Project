
`timescale 1ns/1ps

module tb_riscv_uart_soc;

    logic clk = 0;
    logic rst = 1;

    wire uart_tx, uart_rx;
    wire [31:0] pc_debug, instruction_debug;
    wire stall_debug, forwarding_debug, flush_debug;
    wire mmio_stall_debug;

    integer errors = 0;
    integer checks = 0;
    integer cycles = 0;
    integer mmio_stall_cycles = 0;
    integer tx_falling_edges = 0;

    logic prev_tx = 1;
    logic success = 0;

    // Horloge 1 MHz
    always #500 clk = ~clk;

    // UART en loopback
    assign uart_rx = uart_tx;

    // =====================================
    // SOC RISC-V + UART
    // =====================================

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

    // =====================================
    // ENCODAGE DES INSTRUCTIONS RISC-V
    // =====================================

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
        enc_addi = {
            imm, rs1, 3'b000,
            rd, 7'b0010011
        };
    endfunction

    function automatic [31:0] enc_andi(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        enc_andi = {
            imm, rs1, 3'b111,
            rd, 7'b0010011
        };
    endfunction

    function automatic [31:0] enc_sw(
        input [4:0] rs2, rs1,
        input [11:0] imm
    );
        enc_sw = {
            imm[11:5], rs2, rs1,
            3'b010, imm[4:0],
            7'b0100011
        };
    endfunction

    function automatic [31:0] enc_lw(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        enc_lw = {
            imm, rs1, 3'b010,
            rd, 7'b0000011
        };
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

    // =====================================
    // VERIFICATION AUTOMATIQUE
    // =====================================

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

    // =====================================
    // COMPTEURS DE SIMULATION
    // =====================================

    always @(posedge clk) begin
        if (!rst) begin
            cycles <= cycles + 1;

            if (mmio_stall_debug)
                mmio_stall_cycles <=
                    mmio_stall_cycles + 1;

            if (prev_tx && !uart_tx)
                tx_falling_edges <=
                    tx_falling_edges + 1;

            prev_tx <= uart_tx;
        end
    end

    // =====================================
    // PROGRAMME DE TEST RISC-V
    // =====================================

    initial begin

        #2;

        // Initialiser la memoire d'instructions
        // Sans modifier program.hex
        for (integer k = 0; k < 256; k = k + 1)
            dut.cpu.u_imem.memory[k] =
                32'h00000013;

        // x1 = adresse de base UART
        dut.cpu.u_imem.memory[0] =
            enc_lui(5'd1, 20'h10000);

        // x2 = 0x55
        dut.cpu.u_imem.memory[1] =
            enc_addi(5'd2, 5'd0, 12'h055);

        // Envoyer 0x55 dans TX_DATA
        dut.cpu.u_imem.memory[2] =
            enc_sw(5'd2, 5'd1, 12'd0);

        // Lire STATUS
        dut.cpu.u_imem.memory[3] =
            enc_lw(5'd3, 5'd1, 12'd8);

        // Isoler RX_PENDING
        dut.cpu.u_imem.memory[4] =
            enc_andi(5'd4, 5'd3, 12'd2);

        // Revenir lire STATUS si reception absente
        dut.cpu.u_imem.memory[5] =
            enc_beq(5'd4, 5'd0, 13'h1FF8);

        // Lire RX_DATA
        dut.cpu.u_imem.memory[6] =
            enc_lw(5'd5, 5'd1, 12'd4);

        // Valeur attendue
        dut.cpu.u_imem.memory[7] =
            enc_addi(5'd6, 5'd0, 12'h055);

        // Comparer la valeur recue
        dut.cpu.u_imem.memory[8] =
            enc_beq(5'd5, 5'd6, 13'd8);

        // Marquer une erreur si difference
        dut.cpu.u_imem.memory[9] =
            enc_addi(5'd7, 5'd0, 12'd1);

        // Boucle finale
        dut.cpu.u_imem.memory[10] =
            enc_jal(5'd0, 21'd0);

        // =====================================
        // RESET
        // =====================================

        repeat (5) @(negedge clk);
        rst = 0;

        $display("");
        $display("================================");
        $display("TEST SOC RISC-V + UART AXI4-LITE");
        $display("================================");

        // =====================================
        // ATTENDRE LA RECEPTION
        // =====================================

        for (integer t = 0; t < 3000; t = t + 1) begin
            @(negedge clk);

            if (dut.cpu.u_regfile.registers[5] == 32'h55)
                success = 1;

            if (success)
                break;
        end

        repeat (20) @(negedge clk);

        // =====================================
        // TESTS
        // =====================================

        check(
            success,
            "RISC-V a lu 0x55 depuis RX_DATA"
        );

        check(
            dut.cpu.u_regfile.registers[1] ==
            32'h10000000,
            "Adresse UART dans x1"
        );

        check(
            dut.cpu.u_regfile.registers[2] ==
            32'h55,
            "Donnee 0x55 dans x2"
        );

        check(
            mmio_stall_cycles > 0,
            "Stall du pipeline pendant AXI"
        );

        check(
            tx_falling_edges > 0,
            "Transmission UART detectee"
        );

        check(
            dut.cpu.u_regfile.registers[7] ==
            32'd0,
            "Aucune erreur dans x7"
        );

        // =====================================
        // BILAN FINAL
        // =====================================

        $display("");
        $display("--------------------------------");
        $display("Verifications = %0d", checks);
        $display("Erreurs = %0d", errors);

        if (errors == 0)
            $display(
                "SOC RISC-V + UART : TESTS REUSSIS"
            );
        else
            $display(
                "SOC RISC-V + UART : ECHEC"
            );

        $display("--------------------------------");

        $stop;

    end

endmodule