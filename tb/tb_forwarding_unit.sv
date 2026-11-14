
`timescale 1ns/1ps

module tb_forwarding_unit;

    // =====================================
    // DECLARATION DES SIGNAUX
    // =====================================

    logic [4:0] id_ex_rs1;
    logic [4:0] id_ex_rs2;

    logic [4:0] ex_mem_rd;
    logic       ex_mem_reg_write;

    logic [4:0] mem_wb_rd;
    logic       mem_wb_reg_write;

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    integer tests;
    integer errors;

    // =====================================
    // INSTANTIATION DU DUT
    // =====================================

    forwarding_unit dut (

        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),

        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),

        .forward_a(forward_a),
        .forward_b(forward_b)

    );

    // =====================================
    // VERIFICATION AUTOMATIQUE
    // =====================================

    task automatic check_value(
        input string name,
        input logic [1:0] actual,
        input logic [1:0] expected
    );

        begin

            tests = tests + 1;

            if (actual === expected) begin

                $display("OK : %s", name);

            end

            else begin

                errors = errors + 1;

                $display(
                    "ERREUR : %s attendu=%b obtenu=%b",
                    name,
                    expected,
                    actual
                );

            end

        end

    endtask

    task automatic check_both(
        input string name,
        input logic [1:0] expected_a,
        input logic [1:0] expected_b
    );

        begin

            #1;

            check_value(
                {name, " FORWARD A"},
                forward_a,
                expected_a
            );

            check_value(
                {name, " FORWARD B"},
                forward_b,
                expected_b
            );

        end

    endtask

    // =====================================
    // DEBUT DES TESTS
    // =====================================

    initial begin

        tests = 0;
        errors = 0;

        id_ex_rs1 = 5'd0;
        id_ex_rs2 = 5'd0;

        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1'b0;

        $display("================================");
        $display("ETAPE 22 : FORWARDING UNIT");
        $display("================================");

        // =================================
        // TEST 1 : AUCUN FORWARDING
        // =================================

        $display("TEST 1 : AUCUN FORWARDING");

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd3;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd4;
        mem_wb_reg_write = 1'b0;

        check_both(
            "AUCUN FORWARDING",
            2'b00,
            2'b00
        );

        // =================================
        // TEST 2 : EX/MEM VERS A
        // =================================

        $display("TEST 2 : EX/MEM VERS A");

        id_ex_rs1 = 5'd5;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd5;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1'b0;

        check_both(
            "EX MEM VERS A",
            2'b10,
            2'b00
        );

        // =================================
        // TEST 3 : EX/MEM VERS B
        // =================================

        $display("TEST 3 : EX/MEM VERS B");

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd6;

        ex_mem_rd = 5'd6;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1'b0;

        check_both(
            "EX MEM VERS B",
            2'b00,
            2'b10
        );

        // =================================
        // TEST 4 : EX/MEM VERS A ET B
        // =================================

        $display("TEST 4 : EX/MEM VERS A ET B");

        id_ex_rs1 = 5'd7;
        id_ex_rs2 = 5'd7;

        ex_mem_rd = 5'd7;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1'b0;

        check_both(
            "EX MEM VERS A ET B",
            2'b10,
            2'b10
        );

        // =================================
        // TEST 5 : MEM/WB VERS A
        // =================================

        $display("TEST 5 : MEM/WB VERS A");

        id_ex_rs1 = 5'd8;
        id_ex_rs2 = 5'd2;

        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd8;
        mem_wb_reg_write = 1'b1;

        check_both(
            "MEM WB VERS A",
            2'b01,
            2'b00
        );

        // =================================
        // TEST 6 : MEM/WB VERS B
        // =================================

        $display("TEST 6 : MEM/WB VERS B");

        id_ex_rs1 = 5'd1;
        id_ex_rs2 = 5'd9;

        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd9;
        mem_wb_reg_write = 1'b1;

        check_both(
            "MEM WB VERS B",
            2'b00,
            2'b01
        );

        // =================================
        // TEST 7 : MEM/WB VERS A ET B
        // =================================

        $display("TEST 7 : MEM/WB VERS A ET B");

        id_ex_rs1 = 5'd10;
        id_ex_rs2 = 5'd10;

        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd10;
        mem_wb_reg_write = 1'b1;

        check_both(
            "MEM WB VERS A ET B",
            2'b01,
            2'b01
        );

        // =================================
        // TEST 8 : PRIORITE EX/MEM
        // =================================

        $display("TEST 8 : PRIORITE EX/MEM");

        id_ex_rs1 = 5'd11;
        id_ex_rs2 = 5'd11;

        ex_mem_rd = 5'd11;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd11;
        mem_wb_reg_write = 1'b1;

        check_both(
            "PRIORITE EX MEM",
            2'b10,
            2'b10
        );

        // =================================
        // TEST 9 : FORWARDING MIXTE
        // =================================

        $display("TEST 9 : FORWARDING MIXTE");

        id_ex_rs1 = 5'd12;
        id_ex_rs2 = 5'd13;

        ex_mem_rd = 5'd12;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd13;
        mem_wb_reg_write = 1'b1;

        check_both(
            "FORWARDING MIXTE",
            2'b10,
            2'b01
        );

        // =================================
        // TEST 10 : REGISTRE X0
        // =================================

        $display("TEST 10 : REGISTRE X0");

        id_ex_rs1 = 5'd0;
        id_ex_rs2 = 5'd0;

        ex_mem_rd = 5'd0;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd0;
        mem_wb_reg_write = 1'b1;

        check_both(
            "REGISTRE X0",
            2'b00,
            2'b00
        );

        // =================================
        // TEST 11 : REG WRITE DESACTIVE
        // =================================

        $display("TEST 11 : REG WRITE DESACTIVE");

        id_ex_rs1 = 5'd14;
        id_ex_rs2 = 5'd14;

        ex_mem_rd = 5'd14;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd14;
        mem_wb_reg_write = 1'b0;

        check_both(
            "REG WRITE DESACTIVE",
            2'b00,
            2'b00
        );

        // =================================
        // TEST 12 : PRIORITE SEPAREE
        // =================================

        $display("TEST 12 : PRIORITE SEPAREE");

        id_ex_rs1 = 5'd15;
        id_ex_rs2 = 5'd16;

        ex_mem_rd = 5'd15;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd16;
        mem_wb_reg_write = 1'b1;

        check_both(
            "PRIORITE SEPAREE",
            2'b10,
            2'b01
        );

        // =================================
        // TEST 13 : EX/MEM DESACTIVE
        // =================================

        $display("TEST 13 : EX MEM DESACTIVE");

        id_ex_rs1 = 5'd17;
        id_ex_rs2 = 5'd18;

        ex_mem_rd = 5'd17;
        ex_mem_reg_write = 1'b0;

        mem_wb_rd = 5'd17;
        mem_wb_reg_write = 1'b1;

        check_both(
            "EX MEM DESACTIVE",
            2'b01,
            2'b00
        );

        // =================================
        // TEST 14 : MEM/WB DESACTIVE
        // =================================

        $display("TEST 14 : MEM WB DESACTIVE");

        id_ex_rs1 = 5'd19;
        id_ex_rs2 = 5'd20;

        ex_mem_rd = 5'd20;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd19;
        mem_wb_reg_write = 1'b0;

        check_both(
            "MEM WB DESACTIVE",
            2'b00,
            2'b10
        );

        // =================================
        // TEST 15 : AUCUNE CORRESPONDANCE
        // =================================

        $display("TEST 15 : AUCUNE CORRESPONDANCE");

        id_ex_rs1 = 5'd21;
        id_ex_rs2 = 5'd22;

        ex_mem_rd = 5'd23;
        ex_mem_reg_write = 1'b1;

        mem_wb_rd = 5'd24;
        mem_wb_reg_write = 1'b1;

        check_both(
            "AUCUNE CORRESPONDANCE",
            2'b00,
            2'b00
        );

        // =================================
        // RESULTATS FINAUX
        // =================================

        $display("================================");
        $display("TESTS   : %0d", tests);
        $display("ERREURS : %0d", errors);

        if (errors == 0)
            $display("ETAPE 22 REUSSIE");
        else
            $display("ETAPE 22 ECHOUEE");

        $display("================================");

        $finish;

    end

endmodule