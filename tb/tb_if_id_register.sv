
`timescale 1ns/1ps

module tb_if_id_register;

    logic clk;
    logic rst;
    logic stall;
    logic flush;

    logic [31:0] pc_in;
    logic [31:0] instruction_in;

    logic [31:0] pc_out;
    logic [31:0] instruction_out;

    integer tests;
    integer errors;

    // =====================================
    // INSTANCIATION DU REGISTRE IF/ID
    // =====================================

    if_id_register dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .pc_in(pc_in),
        .instruction_in(instruction_in),
        .pc_out(pc_out),
        .instruction_out(instruction_out)
    );

    // =====================================
    // HORLOGE : PERIODE 10 NS
    // =====================================

    initial clk = 0;

    always #5 clk = ~clk;

    // =====================================
    // TASK DE VERIFICATION
    // =====================================

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string name
    );
        begin
            tests = tests + 1;

            if (actual === expected) begin
                $display("OK : %s", name);
            end
            else begin
                errors = errors + 1;

                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    name,
                    expected,
                    actual
                );
            end
        end
    endtask

    // =====================================
    // TEST PRINCIPAL
    // =====================================

    initial begin

        tests = 0;
        errors = 0;

        rst = 0;
        stall = 0;
        flush = 0;

        pc_in = 0;
        instruction_in = 0;

        $display("==============================");
        $display("ETAPE 18 : REGISTRE IF/ID");
        $display("==============================");

        // =================================
        // TEST 1 : RESET
        // =================================

        #1;
        rst = 1;
        #1;

        check_value(
            pc_out,
            32'd0,
            "RESET PC"
        );

        check_value(
            instruction_out,
            32'd0,
            "RESET INSTRUCTION"
        );

        // =================================
        // TEST 2 : PREMIERE INSTRUCTION
        // =================================

        @(negedge clk);

        rst = 0;

        pc_in = 32'd0;
        instruction_in = 32'h00500093;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd0,
            "PC PREMIERE INSTRUCTION"
        );

        check_value(
            instruction_out,
            32'h00500093,
            "PREMIERE INSTRUCTION"
        );

        // =================================
        // TEST 3 : DEUXIEME INSTRUCTION
        // =================================

        @(negedge clk);

        pc_in = 32'd4;
        instruction_in = 32'h00300113;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd4,
            "PC DEUXIEME INSTRUCTION"
        );

        check_value(
            instruction_out,
            32'h00300113,
            "DEUXIEME INSTRUCTION"
        );

        // =================================
        // TEST 4 : STALL
        // =================================

        @(negedge clk);

        stall = 1;
        pc_in = 32'd8;
        instruction_in = 32'h002081B3;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd4,
            "STALL PC CONSERVE"
        );

        check_value(
            instruction_out,
            32'h00300113,
            "STALL INSTRUCTION CONSERVEE"
        );

        // =================================
        // TEST 5 : REPRISE APRES STALL
        // =================================

        @(negedge clk);

        stall = 0;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd8,
            "REPRISE PC"
        );

        check_value(
            instruction_out,
            32'h002081B3,
            "REPRISE INSTRUCTION"
        );

        // =================================
        // TEST 6 : FLUSH
        // =================================

        @(negedge clk);

        flush = 1;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd0,
            "FLUSH PC"
        );

        check_value(
            instruction_out,
            32'd0,
            "FLUSH INSTRUCTION"
        );

        // =================================
        // TEST 7 : REPRISE APRES FLUSH
        // =================================

        @(negedge clk);

        flush = 0;
        pc_in = 32'd12;
        instruction_in = 32'h0030C233;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd12,
            "PC APRES FLUSH"
        );

        check_value(
            instruction_out,
            32'h0030C233,
            "INSTRUCTION APRES FLUSH"
        );

        // =================================
        // TEST 8 : PRIORITE FLUSH / STALL
        // =================================

        @(negedge clk);

        stall = 1;
        flush = 1;

        @(posedge clk);
        #1;

        check_value(
            pc_out,
            32'd0,
            "PRIORITE FLUSH PC"
        );

        check_value(
            instruction_out,
            32'd0,
            "PRIORITE FLUSH INSTRUCTION"
        );

        // =================================
        // RESULTATS FINAUX
        // =================================

        $display("==============================");
        $display("TESTS  : %0d", tests);
        $display("ERREURS: %0d", errors);

        if (errors == 0)
            $display("ETAPE 18 REUSSIE");
        else
            $display("ETAPE 18 ECHOUEE");

        $display("==============================");

        $finish;

    end

endmodule