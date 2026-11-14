
`timescale 1ns/1ps

module tb_ex_mem_register;

    // =====================================
    // 1. DECLARATION DES SIGNAUX
    // =====================================

    logic clk = 0;
    logic rst;
    logic stall;
    logic flush;

    logic [31:0] pc_in;
    logic [31:0] alu_result_in;
    logic [31:0] rs2_data_in;

    logic [4:0] rd_in;

    logic reg_write_in;
    logic mem_read_in;
    logic mem_write_in;
    logic mem_to_reg_in;

    logic [31:0] pc_out;
    logic [31:0] alu_result_out;
    logic [31:0] rs2_data_out;

    logic [4:0] rd_out;

    logic reg_write_out;
    logic mem_read_out;
    logic mem_write_out;
    logic mem_to_reg_out;

    integer tests = 0;
    integer errors = 0;

    // =====================================
    // 2. GENERATION DE L'HORLOGE
    // =====================================

    always #5 clk = ~clk;

    // =====================================
    // 3. INSTANCIATION EX/MEM
    // =====================================

    ex_mem_register dut (

        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        .pc_in(pc_in),
        .alu_result_in(alu_result_in),
        .rs2_data_in(rs2_data_in),

        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .mem_to_reg_in(mem_to_reg_in),

        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .rs2_data_out(rs2_data_out),

        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),
        .mem_to_reg_out(mem_to_reg_out)

    );

    // =====================================
    // 4. VERIFICATION AUTOMATIQUE
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
    // 5. VERIFICATION DES 8 SORTIES
    // =====================================

    task automatic check_all(
        input logic [31:0] exp_pc,
        input logic [31:0] exp_alu,
        input logic [31:0] exp_rs2,

        input logic [4:0] exp_rd,

        input logic exp_reg_write,
        input logic exp_mem_read,
        input logic exp_mem_write,
        input logic exp_mem_to_reg
    );

        begin

            check_value(
                pc_out,
                exp_pc,
                "PC"
            );

            check_value(
                alu_result_out,
                exp_alu,
                "ALU RESULT"
            );

            check_value(
                rs2_data_out,
                exp_rs2,
                "RS2 DATA"
            );

            check_value(
                {27'b0, rd_out},
                {27'b0, exp_rd},
                "RD"
            );

            check_value(
                {31'b0, reg_write_out},
                {31'b0, exp_reg_write},
                "REG WRITE"
            );

            check_value(
                {31'b0, mem_read_out},
                {31'b0, exp_mem_read},
                "MEM READ"
            );

            check_value(
                {31'b0, mem_write_out},
                {31'b0, exp_mem_write},
                "MEM WRITE"
            );

            check_value(
                {31'b0, mem_to_reg_out},
                {31'b0, exp_mem_to_reg},
                "MEM TO REG"
            );

        end

    endtask

    // =====================================
    // 6. INITIALISATION DES ENTREES
    // =====================================

    task automatic set_inputs;

        begin

            pc_in = 32'd100;
            alu_result_in = 32'd35;
            rs2_data_in = 32'd10;

            rd_in = 5'd3;

            reg_write_in = 1'b1;
            mem_read_in = 1'b0;
            mem_write_in = 1'b0;
            mem_to_reg_in = 1'b0;

        end

    endtask

    // =====================================
    // 7. TESTS PRINCIPAUX
    // =====================================

    initial begin

        rst = 0;
        stall = 0;
        flush = 0;

        pc_in = 0;
        alu_result_in = 0;
        rs2_data_in = 0;

        rd_in = 0;

        reg_write_in = 0;
        mem_read_in = 0;
        mem_write_in = 0;
        mem_to_reg_in = 0;

        $display("==============================");
        $display("ETAPE 20 : REGISTRE EX/MEM");
        $display("==============================");

        // =================================
        // TEST 1 : RESET
        // =================================

        #1;
        rst = 1;
        #1;

        $display("TEST 1 : RESET");

        check_all(
            0, 0, 0, 0,
            0, 0, 0, 0
        );

        // =================================
        // TEST 2 : TRANSFERT NORMAL
        // =================================

        @(negedge clk);

        rst = 0;
        set_inputs();

        @(posedge clk);
        #1;

        $display("TEST 2 : TRANSFERT NORMAL");

        check_all(
            100, 35, 10, 3,
            1, 0, 0, 0
        );

        // =================================
        // TEST 3 : STALL
        // =================================

        @(negedge clk);

        stall = 1;

        pc_in = 32'd200;
        alu_result_in = 32'd99;
        rs2_data_in = 32'd88;

        rd_in = 5'd7;

        reg_write_in = 0;
        mem_read_in = 1;
        mem_write_in = 1;
        mem_to_reg_in = 1;

        @(posedge clk);
        #1;

        $display("TEST 3 : STALL");

        check_all(
            100, 35, 10, 3,
            1, 0, 0, 0
        );

        // =================================
        // TEST 4 : REPRISE APRES STALL
        // =================================

        @(negedge clk);

        stall = 0;

        @(posedge clk);
        #1;

        $display("TEST 4 : REPRISE APRES STALL");

        check_all(
            200, 99, 88, 7,
            0, 1, 1, 1
        );

        // =================================
        // TEST 5 : FLUSH
        // =================================

        @(negedge clk);

        flush = 1;

        @(posedge clk);
        #1;

        $display("TEST 5 : FLUSH");

        check_all(
            0, 0, 0, 0,
            0, 0, 0, 0
        );

        // =================================
        // TEST 6 : REPRISE APRES FLUSH
        // =================================

        @(negedge clk);

        flush = 0;

        pc_in = 32'd300;
        alu_result_in = 32'd50;
        rs2_data_in = 32'd20;

        rd_in = 5'd9;

        reg_write_in = 1;
        mem_read_in = 0;
        mem_write_in = 0;
        mem_to_reg_in = 0;

        @(posedge clk);
        #1;

        $display("TEST 6 : REPRISE APRES FLUSH");

        check_all(
            300, 50, 20, 9,
            1, 0, 0, 0
        );

        // =================================
        // TEST 7 : PRIORITE FLUSH / STALL
        // =================================

        @(negedge clk);

        stall = 1;
        flush = 1;

        @(posedge clk);
        #1;

        $display("TEST 7 : PRIORITE FLUSH");

        check_all(
            0, 0, 0, 0,
            0, 0, 0, 0
        );

        // =================================
        // TEST 8 : PRIORITE RESET
        // =================================

        @(negedge clk);

        stall = 1;
        flush = 1;
        rst = 1;

        #1;

        $display("TEST 8 : PRIORITE RESET");

        check_all(
            0, 0, 0, 0,
            0, 0, 0, 0
        );

        // =================================
        // 8. RESULTATS FINAUX
        // =================================

        $display("==============================");
        $display("TESTS  : %0d", tests);
        $display("ERREURS: %0d", errors);

        if (errors == 0)
            $display("ETAPE 20 REUSSIE");
        else
            $display("ETAPE 20 ECHOUEE");

        $display("==============================");

        $finish;

    end

endmodule