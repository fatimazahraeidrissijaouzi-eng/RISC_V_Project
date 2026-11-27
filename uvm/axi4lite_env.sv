`ifndef AXI4LITE_ENV_SV
`define AXI4LITE_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi4lite_agent.sv"
`include "axi4lite_scoreboard.sv"

class axi4lite_env extends uvm_env;

    `uvm_component_utils(axi4lite_env)

    axi4lite_agent      agent;
    axi4lite_scoreboard scoreboard;

    function new(string name = "axi4lite_env",
                 uvm_component parent = null);

        super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agent = axi4lite_agent::type_id::create(
            "agent", this);

        scoreboard = axi4lite_scoreboard::type_id::create(
            "scoreboard", this);

    endfunction

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        agent.monitor.ap.connect(
            scoreboard.analysis_export);

    endfunction

endclass

`endif