`timescale 1ns/1ps

package axi4lite_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi4lite_transaction.sv"
    `include "axi4lite_sequence.sv"
    `include "axi4lite_sequencer.sv"
    `include "axi4lite_driver.sv"
    `include "axi4lite_monitor.sv"
    `include "axi4lite_agent.sv"
    `include "axi4lite_scoreboard.sv"
    `include "axi4lite_env.sv"
    `include "axi4lite_test.sv"

endpackage