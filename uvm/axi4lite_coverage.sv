`ifndef AXI4LITE_COVERAGE_SV
`define AXI4LITE_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_coverage extends
    uvm_subscriber #(axi4lite_transaction);

    `uvm_component_utils(axi4lite_coverage)

    axi4lite_transaction tr;

    // ==========================================
    // FUNCTIONAL COVERAGE
    // ==========================================

    covergroup axi_cg;

        option.per_instance = 1;

        // Read and write operations
        cp_operation: coverpoint tr.write {
            bins read_op  = {0};
            bins write_op = {1};
        }

        // Register address coverage
        cp_address: coverpoint tr.addr {
            bins addr_00 = {32'h00000000};
            bins addr_04 = {32'h00000004};
            bins addr_08 = {32'h00000008};
            bins addr_0C = {32'h0000000C};

            bins invalid_addr = {32'h00000010};
            bins out_of_range = {32'h00000100};
        }

        // AXI4-Lite response coverage
        cp_response: coverpoint tr.resp {
            bins okay   = {2'b00};
            bins slverr = {2'b10};
            bins decerr = {2'b11};
        }

        // Write strobe coverage
        cp_strobe: coverpoint tr.strb
            iff (tr.write == 1) {

            bins full_write    = {4'hF};
            bins partial_write = {[4'h1:4'hE]};
            bins zero_write    = {4'h0};
        }

        // ======================================
        // CROSS COVERAGE
        // ======================================

        cross_operation_response:
            cross cp_operation, cp_response {

                // Read SLVERR is unreachable
                // in the current UART RTL.
                ignore_bins read_slverr =
                    binsof(cp_operation.read_op) &&
                    binsof(cp_response.slverr);
            }

    endgroup

    // ==========================================
    // CONSTRUCTOR
    // ==========================================

    function new(
        string name = "axi4lite_coverage",
        uvm_component parent = null
    );

        super.new(name, parent);

        axi_cg = new();

    endfunction

    // ==========================================
    // SAMPLE TRANSACTIONS
    // ==========================================

    virtual function void write(
        axi4lite_transaction t
    );

        tr = t;

        axi_cg.sample();

    endfunction

    // ==========================================
    // COVERAGE REPORT
    // ==========================================

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("COVERAGE",
            "===== FUNCTIONAL COVERAGE SUMMARY =====",
            UVM_LOW)

        `uvm_info("COVERAGE",
            $sformatf("Functional Coverage = %0.2f%%",
                axi_cg.get_inst_coverage()),
            UVM_LOW)

    endfunction

endclass

`endif