`ifndef AXI4LITE_AGENT_SV
`define AXI4LITE_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4lite_transaction.sv"
`include "axi4lite_sequencer.sv"
`include "axi4lite_driver.sv"
`include "axi4lite_monitor.sv"

class axi4lite_agent extends uvm_agent;

    `uvm_component_utils(axi4lite_agent)

    axi4lite_sequencer sequencer;
    axi4lite_driver    driver;
    axi4lite_monitor   monitor;

    function new(string name = "axi4lite_agent",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        monitor = axi4lite_monitor::type_id::create(
            "monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin

            sequencer = axi4lite_sequencer::type_id::create(
                "sequencer", this);

            driver = axi4lite_driver::type_id::create(
                "driver", this);

        end

    endfunction

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin

            driver.seq_item_port.connect(
                sequencer.seq_item_export);

        end

    endfunction

endclass

`endif