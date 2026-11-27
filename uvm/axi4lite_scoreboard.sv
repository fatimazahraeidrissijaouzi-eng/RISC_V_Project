`ifndef AXI4LITE_SCOREBOARD_SV
`define AXI4LITE_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi4lite_scoreboard)

    uvm_analysis_imp #(
        axi4lite_transaction,
        axi4lite_scoreboard
    ) analysis_export;

    int total_transactions = 0;
    int write_count = 0;
    int read_count = 0;
    int passed_count = 0;
    int failed_count = 0;

    bit expected_enable = 1'b1;

    function new(
        string name = "axi4lite_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(axi4lite_transaction tr);

        logic [1:0] expected_resp;
        logic [31:0] expected_data;
        bit check_data;
        bit success;

        total_transactions++;

        expected_resp = 2'b00;
        expected_data = 32'h0;
        check_data = 0;
        success = 1;

        if (tr.write)
            write_count++;
        else
            read_count++;

        case (tr.addr)

            32'h00000000: begin
                if (tr.write && tr.strb[0]) begin
                    `uvm_error("SCOREBOARD",
                        "TX write outside current test scope")
                    success = 0;
                end
            end

            32'h00000004: begin
                if (tr.write)
                    expected_resp = 2'b10;
            end

            32'h00000008: begin
                expected_resp = 2'b00;
            end

            32'h0000000C: begin
                if (!tr.write) begin
                    expected_data =
                        {31'b0, expected_enable};
                    check_data = 1;
                end
            end

            default: begin
                expected_resp = 2'b11;

                if (!tr.write) begin
                    expected_data = 32'h0;
                    check_data = 1;
                end
            end

        endcase

        if (tr.resp !== expected_resp) begin

            success = 0;

            `uvm_error("SCOREBOARD",
                $sformatf(
                "Response mismatch addr=%h expected=%b actual=%b",
                tr.addr, expected_resp, tr.resp))

        end

        if (!tr.write && $isunknown(tr.rdata)) begin

            success = 0;

            `uvm_error("SCOREBOARD",
                "Unknown read data")

        end

        if (check_data &&
            tr.rdata !== expected_data) begin

            success = 0;

            `uvm_error("SCOREBOARD",
                $sformatf(
                "Data mismatch addr=%h expected=%h actual=%h",
                tr.addr, expected_data, tr.rdata))

        end

        if (tr.write &&
            tr.addr == 32'h0000000C &&
            tr.strb[0] &&
            expected_resp == 2'b00)
            expected_enable = tr.data[0];

        if (success) begin

            passed_count++;

            `uvm_info("SCOREBOARD",
                $sformatf(
                "PASS addr=%h write=%b resp=%b",
                tr.addr, tr.write, tr.resp),
                UVM_LOW)

        end else begin

            failed_count++;

        end

    endfunction

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("SCOREBOARD",
            "========== SCOREBOARD SUMMARY ==========",
            UVM_NONE)

        `uvm_info("SCOREBOARD",
            $sformatf("Total transactions : %0d",
                total_transactions), UVM_NONE)

        `uvm_info("SCOREBOARD",
            $sformatf("Write transactions : %0d",
                write_count), UVM_NONE)

        `uvm_info("SCOREBOARD",
            $sformatf("Read transactions  : %0d",
                read_count), UVM_NONE)

        `uvm_info("SCOREBOARD",
            $sformatf("Passed checks      : %0d",
                passed_count), UVM_NONE)

        `uvm_info("SCOREBOARD",
            $sformatf("Failed checks      : %0d",
                failed_count), UVM_NONE)

        if (total_transactions == 0 ||
            failed_count != 0)

            `uvm_error("SCOREBOARD",
                "VERIFICATION FAILED")

        else

            `uvm_info("SCOREBOARD",
                "ALL IMPLEMENTED CHECKS PASSED",
                UVM_NONE)

    endfunction

endclass

`endif