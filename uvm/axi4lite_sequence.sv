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

    task send_transaction(
        bit wr,
        bit [31:0] address,
        bit [31:0] value,
        bit [3:0] strobe
    );

        axi4lite_transaction req;

        req = axi4lite_transaction::type_id::create("req");

        start_item(req);

        req.write = wr;
        req.addr  = address;
        req.data  = value;
        req.strb  = strobe;

        finish_item(req);

    endtask

    task body();

        axi4lite_transaction req;

        // 20 constrained-random transactions
        repeat (20) begin

            req = axi4lite_transaction::type_id::create("req");

            start_item(req);

            if (!req.randomize() with {

                addr inside {
                    32'h00000000,
                    32'h00000004,
                    32'h00000008,
                    32'h0000000C
                };

                if (write == 1)
                    addr inside {
                        32'h00000008,
                        32'h0000000C
                    };

                strb == 4'b1111;

            })
                `uvm_fatal("SEQ", "Randomization failed")

            finish_item(req);

        end

        // SLVERR: write to read-only RX_DATA
        send_transaction(1, 32'h00000004,
                         32'h12345678, 4'hF);

        // DECERR: invalid write address
        send_transaction(1, 32'h00000010,
                         32'hAABBCCDD, 4'hF);

        // DECERR: invalid read address
        send_transaction(0, 32'h00000010,
                         32'h0, 4'hF);

        // DECERR: out-of-range write address
        send_transaction(1, 32'h00000100,
                         32'h12345678, 4'hF);

        // DECERR: out-of-range read address
        send_transaction(0, 32'h00000100,
                         32'h0, 4'hF);

        // CONTROL register: disable UART
        send_transaction(1, 32'h0000000C,
                         32'h0, 4'hF);

        send_transaction(0, 32'h0000000C,
                         32'h0, 4'hF);

        // CONTROL register: enable UART
        send_transaction(1, 32'h0000000C,
                         32'h1, 4'hF);

        send_transaction(0, 32'h0000000C,
                         32'h0, 4'hF);

        `uvm_info("SEQ",
            "Random and directed tests completed",
            UVM_LOW)

    endtask

endclass

`endif