`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

class smoke_test extends uvm_test;

    `uvm_component_utils(smoke_test)

    function new(string name = "smoke_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info("UVM_TEST",
                  "UVM IS WORKING SUCCESSFULLY",
                  UVM_LOW)

        #100;

        phase.drop_objection(this);
    endtask

endclass

module uvm_smoke_test;

    initial begin
        run_test("smoke_test");
    end

endmodule