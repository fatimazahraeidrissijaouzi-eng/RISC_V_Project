
`timescale 1ns/1ps

module tb_pc;

    logic clk = 0;
    logic rst;
    logic stall;
    logic branch_taken;
    logic [31:0] branch_target;
    logic [31:0] pc_out;

    pc dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_out(pc_out)
    );

    // Horloge : periode de 10 ns
    always #5 clk = ~clk;

    task automatic check_pc(
        input logic [31:0] expected
    );
        if (pc_out !== expected)
            $fatal(1,
                "ERREUR PC: attendu=%h obtenu=%h",
                expected, pc_out);
        else
            $display("OK PC = %h", pc_out);
    endtask

    initial begin
        rst = 1;
        stall = 0;
        branch_taken = 0;
        branch_target = 0;

        // TEST 1 : RESET
        #2;
        check_pc(32'd0);

        // Desactiver reset avant le front montant
        #1;
        rst = 0;

        // TEST 2 : PC + 4
        @(posedge clk);
        #1;
        check_pc(32'd4);

        // TEST 3 : PC + 4
        @(posedge clk);
        #1;
        check_pc(32'd8);

        // TEST 4 : STALL
        @(negedge clk);
        stall = 1;

        @(posedge clk);
        #1;
        check_pc(32'd8);

        // TEST 5 : BRANCH
        @(negedge clk);
        stall = 0;
        branch_taken = 1;
        branch_target = 32'h00000100;

        @(posedge clk);
        #1;
        check_pc(32'h00000100);

        // TEST 6 : REPRISE
        @(negedge clk);
        branch_taken = 0;

        @(posedge clk);
        #1;
        check_pc(32'h00000104);

        $display("TOUS LES TESTS PC REUSSIS");
        $finish;
    end

endmodule