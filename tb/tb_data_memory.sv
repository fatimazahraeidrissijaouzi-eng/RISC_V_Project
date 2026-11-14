
`timescale 1ns/1ps

module tb_data_memory;

    logic clk;
    logic rst;
    logic mem_read;
    logic mem_write;
    logic [2:0] funct3;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;
    logic valid;

    integer tests = 0;

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

    // Horloge de periode 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Ecriture avec verification de valid
    task automatic write_mem(
        input logic [31:0] addr,
        input logic [2:0] mode,
        input logic [31:0] data,
        input logic expected_valid,
        input string name
    );
        begin
            @(negedge clk);
            address = addr;
            funct3 = mode;
            write_data = data;
            mem_read = 0;
            mem_write = 1;

            #1;
            if (valid !== expected_valid)
                $fatal(1, "ECHEC %s : valid", name);

            @(posedge clk);
            #1;

            tests = tests + 1;
            $display("OK %s", name);

            @(negedge clk);
            mem_write = 0;
        end
    endtask

    // Lecture avec verification des donnees
    task automatic read_mem(
        input logic [31:0] addr,
        input logic [2:0] mode,
        input logic [31:0] expected,
        input logic expected_valid,
        input string name
    );
        begin
            @(negedge clk);
            address = addr;
            funct3 = mode;
            mem_write = 0;
            mem_read = 1;

            #1;

            if (valid !== expected_valid)
                $fatal(1, "ECHEC %s : valid", name);

            if (read_data !== expected)
                $fatal(1,
                    "ECHEC %s : attendu=%h obtenu=%h",
                    name, expected, read_data);

            tests = tests + 1;
            $display("OK %s : %h", name, read_data);

            @(negedge clk);
            mem_read = 0;
        end
    endtask

    initial begin
        rst = 1;
        mem_read = 0;
        mem_write = 0;
        funct3 = 0;
        address = 0;
        write_data = 0;

        #12;
        rst = 0;

        // 1. Ecriture et lecture d'un mot
        write_mem(0, 3'b010, 32'h12345678,
                  1, "SW adresse 0");

        read_mem(0, 3'b010, 32'h12345678,
                 1, "LW adresse 0");

        // 2. Lecture d'octets
        read_mem(0, 3'b100, 32'h00000078,
                 1, "LBU adresse 0");

        read_mem(1, 3'b100, 32'h00000056,
                 1, "LBU adresse 1");

        // 3. Lecture de demi-mots
        read_mem(0, 3'b101, 32'h00005678,
                 1, "LHU adresse 0");

        read_mem(2, 3'b101, 32'h00001234,
                 1, "LHU adresse 2");

        // 4. Ecriture d'un octet negatif
        write_mem(8, 3'b000, 32'h000000FF,
                  1, "SB adresse 8");

        read_mem(8, 3'b000, 32'hFFFFFFFF,
                 1, "LB extension signe");

        read_mem(8, 3'b100, 32'h000000FF,
                 1, "LBU extension zero");

        // 5. Ecriture d'un demi-mot negatif
        write_mem(12, 3'b001, 32'h00008001,
                  1, "SH adresse 12");

        read_mem(12, 3'b001, 32'hFFFF8001,
                 1, "LH extension signe");

        read_mem(12, 3'b101, 32'h00008001,
                 1, "LHU extension zero");

        // 6. Acces a la derniere adresse alignee
        write_mem(1020, 3'b010, 32'hAABBCCDD,
                  1, "SW derniere adresse");

        read_mem(1020, 3'b010, 32'hAABBCCDD,
                 1, "LW derniere adresse");

        // 7. Acces non alignes
        write_mem(1, 3'b010, 32'hDEADBEEF,
                  0, "SW non aligne refuse");

        read_mem(1, 3'b010, 32'h00000000,
                 0, "LW non aligne refuse");

        // 8. Acces hors limites
        read_mem(1024, 3'b100, 32'h00000000,
                 0, "Lecture hors memoire");

        // 9. Verification qu'une ecriture invalide
        // n'a pas modifie le mot precedent
        read_mem(0, 3'b010, 32'h12345678,
                 1, "Memoire non modifiee");

        // 10. Controle d'une operation invalide
        read_mem(0, 3'b111, 32'h00000000,
                 0, "Funct3 invalide");

        $display("------------------------------------");
        $display("TOUS LES TESTS DATA MEMORY REUSSIS");
        $display("Nombre de tests : %0d", tests);
        $display("------------------------------------");

        $finish;
    end

endmodule