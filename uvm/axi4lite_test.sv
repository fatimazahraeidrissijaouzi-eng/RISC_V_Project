`ifndef AXI4LITE_TEST_SV
`define AXI4LITE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4lite_env.sv"
`include "axi4lite_sequence.sv"

class axi4lite_test extends uvm_test;

    `uvm_component_utils(axi4lite_test)

    axi4lite_env env;

    function new(string name = "axi4lite_test",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = axi4lite_env::type_id::create(
            "env", this);

    endfunction

    function void end_of_elaboration_phase(
        uvm_phase phase);

        super.end_of_elaboration_phase(phase);

        uvm_top.print_topology();

    endfunction

    task run_phase(uvm_phase phase);

        axi4lite_sequence seq;

        phase.raise_objection(this);

        seq = axi4lite_sequence::type_id::create("seq");

        `uvm_info("TEST",
            "Starting AXI4-Lite UVM test",
            UVM_LOW)

        seq.start(env.agent.sequencer);

        if (env.scoreboard.total_transactions != 29)
            `uvm_error("TEST",
                "Unexpected number of transactions")

        `uvm_info("TEST",
            "AXI4-Lite UVM test completed",
            UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass

`endif