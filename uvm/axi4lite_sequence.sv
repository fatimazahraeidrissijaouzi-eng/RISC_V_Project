`ifndef AXI4LITE_SEQUENCE_SV
`define AXI4LITE_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_sequence extends
    uvm_sequence #(axi4lite_transaction);

    `uvm_object_utils(axi4lite_sequence)

    function new(string name = "axi4lite_sequence");
        super.new(name);
    endfunction

    task body();

        axi4lite_transaction req;

        repeat (20) begin

            req = axi4lite_transaction::type_id::create("req");

            start_item(req);

            if (!req.randomize())
                `uvm_fatal("SEQ", "Randomization failed")

            finish_item(req);

        end

    endtask

endclass

`endif