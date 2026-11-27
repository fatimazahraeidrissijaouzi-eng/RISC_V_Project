`ifndef AXI4LITE_TRANSACTION_SV
`define AXI4LITE_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4lite_transaction extends uvm_sequence_item;

    rand bit        write;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;

    logic [31:0] rdata;
    logic [1:0]  resp;

    constraint aligned_address {
        addr[1:0] == 2'b00;
    }

    `uvm_object_utils_begin(axi4lite_transaction)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(strb,  UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4lite_transaction");
        super.new(name);
    endfunction

endclass

`endif