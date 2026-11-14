
`timescale 1ns/1ps

module tb_id_ex_register;

    // =====================================
    // 1. SIGNAUX DU TESTBENCH
    // =====================================

    logic clk = 0;
    logic rst;
    logic stall;
    logic flush;

    logic [31:0] pc_in, pc_out;
    logic [31:0] rs1_data_in, rs1_data_out;
    logic [31:0] rs2_data_in, rs2_data_out;
    logic [31:0] immediate_in, immediate_out;

    logic [4:0] rs1_in, rs1_out;
    logic [4:0] rs2_in, rs2_out;
    logic [4:0] rd_in, rd_out;

    logic reg_write_in, reg_write_out;
    logic mem_read_in, mem_read_out;
    logic mem_write_in, mem_write_out;
    logic alu_src_in, alu_src_out;
    logic mem_to_reg_in, mem_to_reg_out;
    logic branch_in, branch_out;
    logic jump_in, jump_out;

    logic [3:0] alu_control_in, alu_control_out;

    integer tests = 0;
    integer errors = 0;

    // =====================================
    // 2. HORLOGE
    // =====================================

    always #5 clk = ~clk;

    // =====================================
    // 3. INSTANCIATION DU MODULE
    // =====================================

    id_ex_register dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),

        .pc_in(pc_in),
        .rs1_data_in(rs1_data_in),
        .rs2_data_in(rs2_data_in),
        .immediate_in(immediate_in),

        .rs1_in(rs1_in),
        .rs2_in(rs2_in),
        .rd_in(rd_in),

        .reg_write_in(reg_write_in),
        .mem_read_in(mem_read_in),
        .mem_write_in(mem_write_in),
        .alu_src_in(alu_src_in),
        .mem_to_reg_in(mem_to_reg_in),
        .branch_in(branch_in),
        .jump_in(jump_in),
        .alu_control_in(alu_control_in),

        .pc_out(pc_out),
        .rs1_data_out(rs1_data_out),
        .rs2_data_out(rs2_data_out),
        .immediate_out(immediate_out),

        .rs1_out(rs1_out),
        .rs2_out(rs2_out),
        .rd_out(rd_out),

        .reg_write_out(reg_write_out),
        .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out),
        .alu_src_out(alu_src_out),
        .mem_to_reg_out(mem_to_reg_out),
        .branch_out(branch_out),
        .jump_out(jump_out),
        .alu_control_out(alu_control_out)
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
                    name, expected, actual
                );
            end
        end
    endtask

    // =====================================
    // 5. VERIFIER TOUS LES SIGNAUX
    // =====================================

    task automatic check_all(
        input logic [31:0] exp_pc,
        input logic [31:0] exp_rs1_data,
        input logic [31:0] exp_rs2_data,
        input logic [31:0] exp_imm,

        input logic [4:0] exp_rs1,
        input logic [4:0] exp_rs2,
        input logic [4:0] exp_rd,

        input logic exp_reg_write,
        input logic exp_mem_read,
        input logic exp_mem_write,
        input logic exp_alu_src,
        input logic exp_mem_to_reg,
        input logic exp_branch,
        input logic exp_jump,
        input logic [3:0] exp_alu_control
    );
        begin

            check_value(pc_out, exp_pc, "PC");

            check_value(
                rs1_data_out, exp_rs1_data, "RS1 DATA"
            );

            check_value(
                rs2_data_out, exp_rs2_data, "RS2 DATA"
            );

            check_value(
                immediate_out, exp_imm, "IMMEDIATE"
            );

            check_value(
                rs1_out, {27'b0, exp_rs1}, "RS1"
            );

            check_value(
                rs2_out, {27'b0, exp_rs2}, "RS2"
            );

            check_value(
                rd_out, {27'b0, exp_rd}, "RD"
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
                {31'b0, alu_src_out},
                {31'b0, exp_alu_src},
                "ALU SRC"
            );

            check_value(
                {31'b0, mem_to_reg_out},
                {31'b0, exp_mem_to_reg},
                "MEM TO REG"
            );

            check_value(
                {31'b0, branch_out},
                {31'b0, exp_branch},
                "BRANCH"
            );

            check_value(
                {31'b0, jump_out},
                {31'b0, exp_jump},
                "JUMP"
            );

            check_value(
                {28'b0, alu_control_out},
                {28'b0, exp_alu_control},
                "ALU CONTROL"
            );

        end
    endtask

    // =====================================
    // 6. INITIALISER LES ENTREES
    // =====================================

    task automatic set_inputs;
        begin

            pc_in = 32'd100;
            rs1_data_in = 32'd25;
            rs2_data_in = 32'd10;
            immediate_in = 32'd8;

            rs1_in = 5'd1;
            rs2_in = 5'd2;
            rd_in = 5'd3;

            reg_write_in = 1'b1;
            mem_read_in = 1'b1;
            mem_write_in = 1'b0;
            alu_src_in = 1'b1;
            mem_to_reg_in = 1'b1;
            branch_in = 1'b0;
            jump_in = 1'b0;
            alu_control_in = 4'd0;

        end
    endtask

    // =====================================
    // 7. TEST PRINCIPAL
    // =====================================

    initial begin

        rst = 0;
        stall = 0;
        flush = 0;

        pc_in = 0;
        rs1_data_in = 0;
        rs2_data_in = 0;
        immediate_in = 0;

        rs1_in = 0;
        rs2_in = 0;
        rd_in = 0;

        reg_write_in = 0;
        mem_read_in = 0;
        mem_write_in = 0;
        alu_src_in = 0;
        mem_to_reg_in = 0;
        branch_in = 0;
        jump_in = 0;
        alu_control_in = 0;

        $display("==============================");
        $display("ETAPE 19 : REGISTRE ID/EX");
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
            0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
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
            100, 25, 10, 8,
            1, 2, 3,
            1, 1, 0, 1, 1, 0, 0, 0
        );

        // =================================
        // TEST 3 : STALL
        // =================================

        @(negedge clk);

        stall = 1;

        pc_in = 32'd200;
        rs1_data_in = 32'd99;
        rs2_data_in = 32'd88;
        immediate_in = 32'd44;

        rs1_in = 5'd7;
        rs2_in = 5'd8;
        rd_in = 5'd9;

        reg_write_in = 0;
        mem_read_in = 0;
        mem_write_in = 1;
        alu_src_in = 0;
        mem_to_reg_in = 0;
        branch_in = 1;
        jump_in = 1;
        alu_control_in = 4'd4;

        @(posedge clk);
        #1;

        $display("TEST 3 : STALL");

        check_all(
            100, 25, 10, 8,
            1, 2, 3,
            1, 1, 0, 1, 1, 0, 0, 0
        );

        // =================================
        // TEST 4 : FLUSH
        // =================================

        @(negedge clk);

        stall = 0;
        flush = 1;

        @(posedge clk);
        #1;

        $display("TEST 4 : FLUSH");

        check_all(
            0, 0, 0, 0,
            0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        );

        // =================================
        // 8. RESULTATS
        // =================================

        $display("==============================");
        $display("TESTS  : %0d", tests);
        $display("ERREURS: %0d", errors);

        if (errors == 0)
            $display("ETAPE 19 REUSSIE");
        else
            $display("ETAPE 19 ECHOUEE");

        $display("==============================");

        $finish;

    end

endmodule