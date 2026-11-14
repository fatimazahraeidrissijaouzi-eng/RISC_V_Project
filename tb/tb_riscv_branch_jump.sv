`timescale 1ns/1ps

module tb_riscv_branch_jump;

    // =====================================
    // SIGNAUX
    // =====================================

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

    // HORLOGE : PERIODE 10 ns
    always #5 clk = ~clk;

    // =====================================
    // VERIFICATION DES RESULTATS
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
    // VERIFICATION DU PC
    // =====================================

    task automatic check_pc(
        input logic [31:0] expected
    );
        begin
            check_value(
                pc_debug,
                expected,
                "PC"
            );

            @(posedge clk);
            #1;
        end
    endtask

    // =====================================
    // TEST PRINCIPAL
    // =====================================

    initial begin

        $display("==========================");
        $display("TEST BRANCH ET JUMP RISC-V");
        $display("==========================");

        // RESET
        repeat (2) @(negedge clk);
        rst = 0;
        #1;

        // =================================
        // TEST DU PROGRAM COUNTER
        // =================================

        check_pc(32'd0);
        check_pc(32'd4);
        check_pc(32'd8);

        // BEQ : saut de 8 vers 16
        check_pc(32'd16);

        // BNE : non pris
        check_pc(32'd20);
        check_pc(32'd24);

        // Instruction JAL
        check_pc(32'd28);

        // JAL : saut vers 36
        check_pc(32'd36);
        check_pc(32'd40);

        // =================================
        // VERIFICATION DES REGISTRES
        // =================================

        // x1 = 5
        check_value(
            dut.u_regfile.registers[1],
            32'd5,
            "x1"
        );

        // x2 = 5
        check_value(
            dut.u_regfile.registers[2],
            32'd5,
            "x2"
        );

        // x3 = 0 : instruction ignoree
        check_value(
            dut.u_regfile.registers[3],
            32'd0,
            "Instruction ignoree x3"
        );

        // x4 = 1
        check_value(
            dut.u_regfile.registers[4],
            32'd1,
            "x4"
        );

        // x5 = 99 : BNE non pris
        check_value(
            dut.u_regfile.registers[5],
            32'd99,
            "BNE non pris x5"
        );

        // x6 = 32 : adresse retour JAL
        check_value(
            dut.u_regfile.registers[6],
            32'd32,
            "Adresse retour JAL"
        );

        // x7 = 0 : instruction ignoree
        check_value(
            dut.u_regfile.registers[7],
            32'd0,
            "Instruction ignoree x7"
        );

        // x8 = 7
        check_value(
            dut.u_regfile.registers[8],
            32'd7,
            "x8"
        );

        // =================================
        // RESULTATS FINAUX
        // =================================

        $display("==========================");
        $display("Tests : %0d", tests);
        $display("Erreurs : %0d", errors);

        if (errors == 0) begin
            $display("TEST BRANCH/JUMP REUSSI");
        end
        else begin
            $display("ECHEC TEST BRANCH/JUMP");
        end

        $finish;
    end

endmodule