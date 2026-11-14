
`timescale 1ns/1ps

module tb_hazard_detection_unit;

    // =====================================
    // DECLARATION DES SIGNAUX
    // =====================================

    logic [4:0] id_ex_rd;
    logic       id_ex_mem_read;

    logic [4:0] if_id_rs1;
    logic [4:0] if_id_rs2;

    logic pc_write;
    logic if_id_write;
    logic control_mux_sel;

    integer tests;
    integer errors;

    // =====================================
    // INSTANTIATION DU DUT
    // =====================================

    hazard_detection_unit dut (

        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),

        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),

        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_mux_sel(control_mux_sel)

    );

    // =====================================
    // VERIFICATION AUTOMATIQUE
    // =====================================

    task automatic check_value(
        input string name,
        input logic actual,
        input logic expected
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

    // =====================================
    // VERIFICATION DES TROIS SORTIES
    // =====================================

    task automatic check_all(
        input string name,
        input logic expected_pc,
        input logic expected_if_id,
        input logic expected_mux
    );

        begin

            #1;

            check_value(
                {name, " PC WRITE"},
                pc_write,
                expected_pc
            );

            check_value(
                {name, " IF ID WRITE"},
                if_id_write,
                expected_if_id
            );

            check_value(
                {name, " CONTROL MUX"},
                control_mux_sel,
                expected_mux
            );

        end

    endtask

    // =====================================
    // DEBUT DES TESTS
    // =====================================

    initial begin

        tests  = 0;
        errors = 0;

        id_ex_rd       = 5'd0;
        id_ex_mem_read = 1'b0;

        if_id_rs1 = 5'd0;
        if_id_rs2 = 5'd0;

        $display("================================");
        $display("ETAPE 23 : HAZARD DETECTION UNIT");
        $display("================================");

        // =================================
        // TEST 1 : AUCUN HAZARD
        // =================================

        $display("TEST 1 : AUCUN HAZARD");

        id_ex_rd       = 5'd5;
        id_ex_mem_read = 1'b0;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd2;

        check_all(
            "AUCUN HAZARD",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 2 : LOAD-USE SUR RS1
        // =================================

        $display("TEST 2 : LOAD USE RS1");

        id_ex_rd       = 5'd5;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd5;
        if_id_rs2 = 5'd2;

        check_all(
            "LOAD USE RS1",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 3 : LOAD-USE SUR RS2
        // =================================

        $display("TEST 3 : LOAD USE RS2");

        id_ex_rd       = 5'd6;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd1;
        if_id_rs2 = 5'd6;

        check_all(
            "LOAD USE RS2",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 4 : LOAD-USE SUR RS1 ET RS2
        // =================================

        $display("TEST 4 : LOAD USE RS1 ET RS2");

        id_ex_rd       = 5'd7;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd7;
        if_id_rs2 = 5'd7;

        check_all(
            "LOAD USE RS1 RS2",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 5 : REGISTRE X0
        // =================================

        $display("TEST 5 : REGISTRE X0");

        id_ex_rd       = 5'd0;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd0;
        if_id_rs2 = 5'd0;

        check_all(
            "REGISTRE X0",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 6 : MEM READ DESACTIVE
        // =================================

        $display("TEST 6 : MEM READ DESACTIVE");

        id_ex_rd       = 5'd8;
        id_ex_mem_read = 1'b0;

        if_id_rs1 = 5'd8;
        if_id_rs2 = 5'd8;

        check_all(
            "MEM READ DESACTIVE",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 7 : AUCUNE CORRESPONDANCE
        // =================================

        $display("TEST 7 : AUCUNE CORRESPONDANCE");

        id_ex_rd       = 5'd9;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd10;
        if_id_rs2 = 5'd11;

        check_all(
            "AUCUNE CORRESPONDANCE",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 8 : DEPENDANCE RS1
        // =================================

        $display("TEST 8 : DEPENDANCE RS1");

        id_ex_rd       = 5'd12;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd12;
        if_id_rs2 = 5'd13;

        check_all(
            "DEPENDANCE RS1",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 9 : DEPENDANCE RS2
        // =================================

        $display("TEST 9 : DEPENDANCE RS2");

        id_ex_rd       = 5'd14;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd15;
        if_id_rs2 = 5'd14;

        check_all(
            "DEPENDANCE RS2",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 10 : DEPENDANCE DOUBLE
        // =================================

        $display("TEST 10 : DEPENDANCE DOUBLE");

        id_ex_rd       = 5'd16;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd16;
        if_id_rs2 = 5'd16;

        check_all(
            "DEPENDANCE DOUBLE",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 11 : X0 SUR RS1
        // =================================

        $display("TEST 11 : X0 SUR RS1");

        id_ex_rd       = 5'd0;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd0;
        if_id_rs2 = 5'd17;

        check_all(
            "X0 SUR RS1",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 12 : X0 SUR RS2
        // =================================

        $display("TEST 12 : X0 SUR RS2");

        id_ex_rd       = 5'd0;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd18;
        if_id_rs2 = 5'd0;

        check_all(
            "X0 SUR RS2",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 13 : LOAD X31
        // =================================

        $display("TEST 13 : LOAD X31");

        id_ex_rd       = 5'd31;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd31;
        if_id_rs2 = 5'd1;

        check_all(
            "LOAD X31",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 14 : LOAD X1
        // =================================

        $display("TEST 14 : LOAD X1");

        id_ex_rd       = 5'd1;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd2;
        if_id_rs2 = 5'd1;

        check_all(
            "LOAD X1",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 15 : LOAD SANS DEPENDANCE
        // =================================

        $display("TEST 15 : LOAD SANS DEPENDANCE");

        id_ex_rd       = 5'd20;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd21;
        if_id_rs2 = 5'd22;

        check_all(
            "LOAD SANS DEPENDANCE",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 16 : ALU AVEC DEPENDANCE
        // =================================

        $display("TEST 16 : ALU AVEC DEPENDANCE");

        id_ex_rd       = 5'd23;
        id_ex_mem_read = 1'b0;

        if_id_rs1 = 5'd23;
        if_id_rs2 = 5'd23;

        check_all(
            "ALU AVEC DEPENDANCE",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 17 : LOAD RS1 UNIQUEMENT
        // =================================

        $display("TEST 17 : LOAD RS1 UNIQUEMENT");

        id_ex_rd       = 5'd24;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd24;
        if_id_rs2 = 5'd25;

        check_all(
            "LOAD RS1 UNIQUEMENT",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 18 : LOAD RS2 UNIQUEMENT
        // =================================

        $display("TEST 18 : LOAD RS2 UNIQUEMENT");

        id_ex_rd       = 5'd26;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd27;
        if_id_rs2 = 5'd26;

        check_all(
            "LOAD RS2 UNIQUEMENT",
            1'b0, 1'b0, 1'b1
        );

        // =================================
        // TEST 19 : MEM READ DESACTIVE
        // =================================

        $display("TEST 19 : MEM READ DESACTIVE");

        id_ex_rd       = 5'd28;
        id_ex_mem_read = 1'b0;

        if_id_rs1 = 5'd28;
        if_id_rs2 = 5'd28;

        check_all(
            "MEM READ DESACTIVE 2",
            1'b1, 1'b1, 1'b0
        );

        // =================================
        // TEST 20 : AUCUN HAZARD FINAL
        // =================================

        $display("TEST 20 : AUCUN HAZARD FINAL");

        id_ex_rd       = 5'd29;
        id_ex_mem_read = 1'b1;

        if_id_rs1 = 5'd30;
        if_id_rs2 = 5'd31;

        check_all(
            "AUCUN HAZARD FINAL",
            1'b1, 1'b1, 1'b0
        );

        // =====================================
        // RESULTATS FINAUX
        // =====================================

        $display("================================");
        $display("TESTS   : %0d", tests);
        $display("ERREURS : %0d", errors);

        if ((tests == 60) && (errors == 0))
            $display("ETAPE 23 REUSSIE");
        else
            $display("ETAPE 23 ECHOUEE");

        $display("================================");

        $finish;

    end

endmodule