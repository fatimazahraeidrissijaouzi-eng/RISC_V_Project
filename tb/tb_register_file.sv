
`timescale 1ns/1ps

module tb_register_file;

    logic clk = 0;
    logic rst;
    logic reg_write;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data, rs2_data;

    register_file dut (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Horloge : periode de 10 ns
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        reg_write = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        rd_data = 0;

        #12;
        rst = 0;

        // Ecrire 25 dans x5
        @(negedge clk);
        reg_write = 1;
        rd_addr = 5;
        rd_data = 25;

        @(posedge clk);
        #1;
        rs1_addr = 5;
        #1;

        if (rs1_data !== 25)
            $fatal(1, "Erreur lecture x5");

        // Ecrire 100 dans x10
        @(negedge clk);
        rd_addr = 10;
        rd_data = 100;

        @(posedge clk);
        #1;
        rs2_addr = 10;
        #1;

        if (rs2_data !== 100)
            $fatal(1, "Erreur lecture x10");

        // Verifier x0 = 0
        @(negedge clk);
        rd_addr = 0;
        rd_data = 999;

        @(posedge clk);
        #1;
        rs1_addr = 0;
        #1;

        if (rs1_data !== 0)
            $fatal(1, "Erreur x0");

        reg_write = 0;

        $display("TOUS LES TESTS REGISTER FILE REUSSIS");
        $finish;
    end

endmodule