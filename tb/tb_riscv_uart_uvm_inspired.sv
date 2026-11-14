
`timescale 1ns/1ps

// ==========================================
// ETAPE 30 : VERIFICATION UVM-INSPIRED
// ==========================================

// Transaction de test
class uart_transaction;
    bit [7:0] expected_data;

    function new(bit [7:0] data = 8'h55);
        expected_data = data;
    endfunction
endclass

// ==========================================
// SEQUENCER
// ==========================================

class uart_sequencer;

    function uart_transaction next_item();
        uart_transaction tr;
        tr = new(8'h55);
        $display("[SEQUENCER] Test UART 0x%02h",
                 tr.expected_data);
        return tr;
    endfunction

endclass

// ==========================================
// DRIVER
// ==========================================

class uart_driver;

    task automatic start_test();
        $display("[DRIVER] Demarrage du scenario");
    endtask

endclass

// ==========================================
// MONITOR
// ==========================================

class uart_monitor;

    integer stall_cycles;
    integer tx_edges;

    function new();
        stall_cycles = 0;
        tx_edges = 0;
    endfunction

    function void observe(
        bit stall_active,
        bit tx_falling
    );
        if (stall_active)
            stall_cycles++;

        if (tx_falling)
            tx_edges++;
    endfunction

    function void report();
        $display("[MONITOR] Stalls AXI = %0d",
                 stall_cycles);
        $display("[MONITOR] Fronts TX = %0d",
                 tx_edges);
    endfunction

endclass

// ==========================================
// SCOREBOARD
// ==========================================

class uart_scoreboard;

    integer checks;
    integer errors;

    function new();
        checks = 0;
        errors = 0;
    endfunction

    function void check(
        bit condition,
        string description
    );
        checks++;

        if (condition)
            $display("[PASS] %s", description);
        else begin
            errors++;
            $display("[FAIL] %s", description);
        end
    endfunction

    function void report();
        $display("");
        $display("================================");
        $display("RESULTATS UVM-INSPIRED");
        $display("Tests  = %0d", checks);
        $display("Errors = %0d", errors);

        if (errors == 0)
            $display("UVM-INSPIRED : TESTS REUSSIS");
        else
            $display("UVM-INSPIRED : ECHEC");

        $display("================================");
    endfunction

endclass

// ==========================================
// TESTBENCH PRINCIPAL
// ==========================================

module tb_riscv_uart_uvm_inspired;

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

    bit previous_tx = 1;
    bit success = 0;

    uart_sequencer sequencer;
    uart_driver driver;
    uart_monitor monitor;
    uart_scoreboard scoreboard;
    uart_transaction transaction;

    // Horloge 1 MHz
    always #500 clk = ~clk;

    // UART loopback
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

    // ==========================================
    // ENCODAGE RISC-V
    // ==========================================

    function automatic [31:0] enc_lui(
        input [4:0] rd,
        input [19:0] imm
    );
        return {imm, rd, 7'b0110111};
    endfunction

    function automatic [31:0] enc_addi(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        return {
            imm, rs1, 3'b000,
            rd, 7'b0010011
        };
    endfunction

    function automatic [31:0] enc_andi(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        return {
            imm, rs1, 3'b111,
            rd, 7'b0010011
        };
    endfunction

    function automatic [31:0] enc_sw(
        input [4:0] rs2, rs1,
        input [11:0] imm
    );
        return {
            imm[11:5], rs2, rs1,
            3'b010, imm[4:0],
            7'b0100011
        };
    endfunction

    function automatic [31:0] enc_lw(
        input [4:0] rd, rs1,
        input [11:0] imm
    );
        return {
            imm, rs1, 3'b010,
            rd, 7'b0000011
        };
    endfunction

    function automatic [31:0] enc_beq(
        input [4:0] rs1, rs2,
        input [12:0] imm
    );
        return {
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
        return {
            imm[20], imm[10:1],
            imm[11], imm[19:12],
            rd, 7'b1101111
        };
    endfunction

    // ==========================================
    // MONITOR DES SIGNAUX
    // ==========================================

    always @(posedge clk) begin
        if (!rst && monitor != null) begin
            monitor.observe(
                mmio_stall_debug,
                previous_tx && !uart_tx
            );
            previous_tx = uart_tx;
        end
    end

    // ==========================================
    // SCENARIO PRINCIPAL
    // ==========================================

    initial begin

        sequencer = new();
        driver = new();
        monitor = new();
        scoreboard = new();

        transaction = sequencer.next_item();

        // Charger le programme de test
        #2;

        for (integer i = 0; i < 256; i++)
            dut.cpu.u_imem.memory[i] =
                32'h00000013;

        // x1 = 0x10000000
        dut.cpu.u_imem.memory[0] =
            enc_lui(5'd1, 20'h10000);

        // x2 = 0x55
        dut.cpu.u_imem.memory[1] =
            enc_addi(5'd2, 5'd0, 12'h055);

        // UART TX_DATA
        dut.cpu.u_imem.memory[2] =
            enc_sw(5'd2, 5'd1, 12'd0);

        // UART STATUS
        dut.cpu.u_imem.memory[3] =
            enc_lw(5'd3, 5'd1, 12'd8);

        // RX_PENDING
        dut.cpu.u_imem.memory[4] =
            enc_andi(5'd4, 5'd3, 12'd2);

        // Attendre la reception
        dut.cpu.u_imem.memory[5] =
            enc_beq(5'd4, 5'd0, 13'h1FF8);

        // UART RX_DATA
        dut.cpu.u_imem.memory[6] =
            enc_lw(5'd5, 5'd1, 12'd4);

        // Valeur attendue
        dut.cpu.u_imem.memory[7] =
            enc_addi(5'd6, 5'd0, 12'h055);

        // Comparaison
        dut.cpu.u_imem.memory[8] =
            enc_beq(5'd5, 5'd6, 13'd8);

        // Erreur si difference
        dut.cpu.u_imem.memory[9] =
            enc_addi(5'd7, 5'd0, 12'd1);

        // Boucle finale
        dut.cpu.u_imem.memory[10] =
            enc_jal(5'd0, 21'd0);

        repeat (5) @(negedge clk);
        rst = 0;

        driver.start_test();

        // Timeout de securite
        for (integer t = 0; t < 3000; t++) begin
            @(negedge clk);

            if (dut.cpu.u_regfile.registers[5] ==
                {24'd0, transaction.expected_data})
                success = 1;

            if (success)
                break;
        end

        repeat (20) @(negedge clk);

        // ======================================
        // SCOREBOARD
        // ======================================

        scoreboard.check(
            success,
            "Reception UART correcte"
        );

        scoreboard.check(
            dut.cpu.u_regfile.registers[1] ==
            32'h10000000,
            "Adresse UART correcte"
        );

        scoreboard.check(
            dut.cpu.u_regfile.registers[2] ==
            32'h55,
            "Donnee transmise correcte"
        );

        scoreboard.check(
            monitor.stall_cycles > 0,
            "Stall AXI detecte"
        );

        scoreboard.check(
            monitor.tx_edges > 0,
            "Activite TX detectee"
        );

        scoreboard.check(
            dut.cpu.u_regfile.registers[7] == 0,
            "Registre erreur x7 = 0"
        );

        monitor.report();
        scoreboard.report();

        $stop;
    end

endmodule