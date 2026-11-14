
`timescale 1ns/1ps

module tb_riscv_core;

    logic clk = 0;
    logic rst = 1;

    logic [31:0] pc_debug;
    logic [31:0] instruction_debug;

    integer tests = 0;
    integer errors = 0;

    // =====================================
    // PROCESSEUR RISC-V
    // =====================================

    riscv_core dut (
        .clk(clk),
        .rst(rst),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug)
    );

    // Horloge : periode de 10 ns
    always #5 clk = ~clk;

    // =====================================
    // VERIFICATION AUTOMATIQUE
    // =====================================

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input string test_name
    );
        begin
            tests = tests + 1;

            if (actual === expected)
                $display("OK : %s", test_name);
            else begin
                errors = errors + 1;
                $display(
                    "ERREUR : %s attendu=%h obtenu=%h",
                    test_name, expected, actual
                );
            end
        end
    endtask

    // =====================================
    // VERIFICATION DES INSTRUCTIONS
    // =====================================

    task automatic check_instruction(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instr
    );
        begin
            check_value(
                pc_debug,
                expected_pc,
                "Program Counter"
            );

            check_value(
                instruction_debug,
                expected_instr,
                "Instruction"
            );

            @(posedge clk);
            #1;
        end
    endtask

    // =====================================
    // PROGRAMME PRINCIPAL DE TEST
    // =====================================

    initial begin

        $display("============================");
        $display("TEST RISC-V INTEGRE");
        $display("============================");

        // Reset
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // =====================================
        // TEST DES 8 INSTRUCTIONS
        // =====================================

        check_instruction(32'd0,  32'h00500093);
        check_instruction(32'd4,  32'h00A00113);
        check_instruction(32'd8,  32'h002081B3);
        check_instruction(32'd12, 32'h00302023);
        check_instruction(32'd16, 32'h00002203);
        check_instruction(32'd20, 32'h004182B3);
        check_instruction(32'd24, 32'h00128313);
        check_instruction(32'd28, 32'h00000013);

        // =====================================
        // VERIFICATION DU PC FINAL
        // =====================================

        check_value(
            pc_debug,
            32'd32,
            "PC final"
        );

        // =====================================
        // VERIFICATION DES REGISTRES
        // =====================================

        check_value(
            dut.u_regfile.registers[0],
            32'd0,
            "Registre x0"
        );

        check_value(
            dut.u_regfile.registers[1],
            32'd5,
            "Registre x1"
        );

        check_value(
            dut.u_regfile.registers[2],
            32'd10,
            "Registre x2"
        );

        check_value(
            dut.u_regfile.registers[3],
            32'd15,
            "Registre x3"
        );

        check_value(
            dut.u_regfile.registers[4],
            32'd15,
            "Registre x4"
        );

        check_value(
            dut.u_regfile.registers[5],
            32'd30,
            "Registre x5"
        );

        check_value(
            dut.u_regfile.registers[6],
            32'd31,
            "Registre x6"
        );

        // =====================================
        // VERIFICATION DE LA MEMOIRE RAM
        // =====================================

        // Adresse 0 : valeur 15 = 0x0F
        check_value(
            {24'b0, dut.u_dmem.memory[0]},
            32'd15,
            "Memoire adresse 0"
        );

        // Adresse 1 : 0x00
        check_value(
            {24'b0, dut.u_dmem.memory[1]},
            32'd0,
            "Memoire adresse 1"
        );

        // Adresse 2 : 0x00
        check_value(
            {24'b0, dut.u_dmem.memory[2]},
            32'd0,
            "Memoire adresse 2"
        );

        // Adresse 3 : 0x00
        check_value(
            {24'b0, dut.u_dmem.memory[3]},
            32'd0,
            "Memoire adresse 3"
        );

        // Reconstituer le mot de 32 bits
        check_value(
            {
                dut.u_dmem.memory[3],
                dut.u_dmem.memory[2],
                dut.u_dmem.memory[1],
                dut.u_dmem.memory[0]
            },
            32'd15,
            "Mot memoire 32 bits"
        );

        // =====================================
        // RESULTATS FINAUX
        // =====================================

        $display("============================");
        $display("Nombre de tests : %0d", tests);
        $display("Nombre d'erreurs : %0d", errors);

        if (errors == 0)
            $display("TOUS LES TESTS REUSSIS");
        else
            $display("ECHEC DES TESTS");

        $finish;
    end

endmodule