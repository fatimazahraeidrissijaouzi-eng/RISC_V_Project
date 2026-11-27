`ifndef AXI4LITE_SEQUENCER_SV
`define AXI4LITE_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_sequencer extends
    uvm_sequencer #(axi4lite_transaction);

    `uvm_component_utils(axi4lite_sequencer)

    function new(string name = "axi4lite_sequencer",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

endclass

`endif