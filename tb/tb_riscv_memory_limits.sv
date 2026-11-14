
`timescale 1ns/1ps

module tb_riscv_memory_limits;

    logic clk = 0;
    logic rst = 1;

    logic mem_read = 0;
    logic mem_write = 0;
    logic [2:0] funct3 = 0;
    logic [31:0] address = 0;
    logic [31:0] write_data = 0;

    logic [31:0] read_data;
    logic valid;

    integer tests = 0;
    integer errors = 0;

    // Module memoire a tester
    data_memory dut (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .valid(valid)
    );

    always #5 clk = ~clk;

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string name
    );
        begin
            tests = tests + 1;

            if (actual === expected)
                $display("OK : %s", name);
            else begin
                errors = errors + 1;
                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    name, expected, actual
                );
            end
        end
    endtask

    initial begin

        $display("============================");
        $display("ETAPE 14 : TESTS MEMOIRE");
        $display("============================");

        // RESET
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // TEST 1 : SW valide a l'adresse 64
        @(negedge clk);
        address = 32'd64;
        funct3 = 3'b010;
        write_data = 32'h12345678;
        mem_write = 1;
        #1;
        check_value(valid, 1, "SW valide");

        @(posedge clk);
        #1;
        check_value(
            dut.memory[16],
            32'h12345678,
            "Ecriture SW"
        );

        // TEST 2 : LW valide
        @(negedge clk);
        mem_write = 0;
        mem_read = 1;
        #1;

        check_value(valid, 1, "LW valide");
        check_value(
            read_data,
            32'h12345678,
            "Lecture LW"
        );

        // TEST 3 : LW non aligne
        address = 32'd65;
        #1;
        check_value(valid, 0, "LW non aligne");

        // TEST 4 : LH adresse impaire
        funct3 = 3'b001;
        #1;
        check_value(valid, 0, "LH non aligne");

        // TEST 5 : LW hors memoire
        address = 32'd1024;
        funct3 = 3'b010;
        #1;
        check_value(valid, 0, "LW hors memoire");

        // TEST 6 : SW hors memoire
        mem_read = 0;
        mem_write = 1;
        write_data = 32'hFFFFFFFF;
        #1;
        check_value(valid, 0, "SW hors memoire");

        @(posedge clk);
        #1;
        check_value(
            dut.memory[16],
            32'h12345678,
            "Memoire protegee"
        );

        // TEST 7 : SB derniere adresse
        @(negedge clk);
        address = 32'd1023;
        funct3 = 3'b000;
        write_data = 32'h000000AB;
        #1;
        check_value(valid, 1, "SB adresse 1023");

        @(posedge clk);
        #1;
        check_value(
            dut.memory[255],
            32'hAB000000,
            "SB derniere case"
        );

        // TEST 8 : Instruction invalide
        @(negedge clk);
        mem_write = 0;
        mem_read = 1;
        address = 32'd64;
        funct3 = 3'b111;
        #1;
        check_value(valid, 0, "Funct3 invalide");

        // TEST 9 : Ecriture desactivee
        mem_read = 0;
        mem_write = 0;
        address = 32'd64;
        funct3 = 3'b010;
        write_data = 32'hDEADBEEF;
        #1;
        check_value(valid, 1, "Memoire inactive");

        @(posedge clk);
        #1;
        check_value(
            dut.memory[16],
            32'h12345678,
            "Aucune ecriture parasite"
        );

        $display("============================");
        $display("TESTS : %0d", tests);
        $display("ERREURS : %0d", errors);

        if (errors == 0)
            $display("ETAPE 14 REUSSIE");
        else
            $display("ETAPE 14 ECHOUEE");

        $display("============================");

        $finish;

    end

endmodule