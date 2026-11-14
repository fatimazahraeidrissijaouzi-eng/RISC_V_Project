
`timescale 1ns/1ps

module forwarding_unit (

    input logic [4:0] id_ex_rs1,
    input logic [4:0] id_ex_rs2,

    input logic [4:0] ex_mem_rd,
    input logic       ex_mem_reg_write,

    input logic [4:0] mem_wb_rd,
    input logic       mem_wb_reg_write,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b

);

    // =====================================
    // ETAPE 22 : FORWARDING UNIT
    // =====================================
    //
    // 00 : Pas de forwarding
    // 10 : Forwarding depuis EX/MEM
    // 01 : Forwarding depuis MEM/WB
    //
    // Priorite EX/MEM sur MEM/WB
    //
    // x0 ne doit jamais etre forwarde
    // =====================================

    always_comb begin

        forward_a = 2'b00;
        forward_b = 2'b00;

        // =================================
        // FORWARDING OPERANDE A
        // =================================

        if (
            ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1)
        ) begin

            forward_a = 2'b10;

        end

        else if (
            mem_wb_reg_write &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs1)
        ) begin

            forward_a = 2'b01;

        end

        // =================================
        // FORWARDING OPERANDE B
        // =================================

        if (
            ex_mem_reg_write &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2)
        ) begin

            forward_b = 2'b10;

        end

        else if (
            mem_wb_reg_write &&
            (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs2)
        ) begin

            forward_b = 2'b01;

        end

    end

endmodule