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

    function new(string name = "axi4lite_scoreboard",
                 uvm_component parent = null);

        super.new(name, parent);

        analysis_export = new("analysis_export", this);

    endfunction

    function void write(axi4lite_transaction tr);

        total_transactions++;

        if (tr.write)
            write_count++;
        else
            read_count++;

        if ($isunknown(tr.resp)) begin

            failed_count++;

            `uvm_error("SCOREBOARD",
                "Unknown AXI response")

        end else if (tr.resp == 2'b00) begin

            if (!tr.write && $isunknown(tr.rdata)) begin

                failed_count++;

                `uvm_error("SCOREBOARD",
                    "Unknown read data")

            end else begin

                passed_count++;

                `uvm_info("SCOREBOARD",
                    $sformatf(
                    "Response PASS: addr=%h write=%b",
                    tr.addr, tr.write),
                    UVM_LOW)

            end

        end else begin

            failed_count++;

            `uvm_error("SCOREBOARD",
                $sformatf(
                "Unexpected AXI response: addr=%h resp=%b",
                tr.addr, tr.resp))

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

        if (total_transactions == 0)
            `uvm_error("SCOREBOARD",
                "No transactions received")

        else if (failed_count == 0)
            `uvm_info("SCOREBOARD",
                "ALL RESPONSE CHECKS PASSED",
                UVM_NONE)

        else
            `uvm_error("SCOREBOARD",
                "RESPONSE CHECKS FAILED")

    endfunction

endclass

`endif