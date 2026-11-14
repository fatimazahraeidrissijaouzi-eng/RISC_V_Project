
`timescale 1ns/1ps

module hazard_detection_unit (

    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read,

    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,

    output logic       pc_write,
    output logic       if_id_write,
    output logic       control_mux_sel

);

    // =========================================
    // ETAPE 23 : HAZARD DETECTION UNIT
    // =========================================
    //
    // Detection des dependances LOAD-USE
    //
    // id_ex_rd       : destination de LOAD
    // id_ex_mem_read : instruction LOAD active
    // if_id_rs1      : registre source 1
    // if_id_rs2      : registre source 2
    //
    // pc_write = 0       : bloquer PC
    // if_id_write = 0    : bloquer IF/ID
    // control_mux_sel = 1 : inserer bulle
    //
    // x0 ne provoque jamais de hazard
    // =========================================

    always_comb begin

        // Fonctionnement normal
        pc_write        = 1'b1;
        if_id_write     = 1'b1;
        control_mux_sel = 1'b0;

        // Detection LOAD-USE
        if (
            id_ex_mem_read &&
            (id_ex_rd != 5'd0) &&
            (
                (id_ex_rd == if_id_rs1) ||
                (id_ex_rd == if_id_rs2)
            )
        ) begin

            // Bloquer le pipeline
            pc_write        = 1'b0;
            if_id_write     = 1'b0;

            // Inserer une bulle
            control_mux_sel = 1'b1;

        end

    end

endmodule