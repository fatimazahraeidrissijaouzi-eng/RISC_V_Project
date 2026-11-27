`ifndef AXI4LITE_DRIVER_SV
`define AXI4LITE_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_driver extends
    uvm_driver #(axi4lite_transaction);

    `uvm_component_utils(axi4lite_driver)

    virtual axi4lite_if vif;

    function new(string name = "axi4lite_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi4lite_if)::get(
            this, "", "vif", vif))
            `uvm_fatal("DRIVER", "Virtual interface not found")

    endfunction

    task run_phase(uvm_phase phase);

        axi4lite_transaction tr;

        vif.awaddr  = 0;
        vif.awvalid = 0;
        vif.wdata   = 0;
        vif.wstrb   = 0;
        vif.wvalid  = 0;
        vif.bready  = 0;
        vif.araddr  = 0;
        vif.arvalid = 0;
        vif.rready  = 0;

        wait (vif.aresetn === 1'b1);

        forever begin

            seq_item_port.get_next_item(tr);

            if (tr.write)
                drive_write(tr);
            else
                drive_read(tr);

            seq_item_port.item_done();

        end

    endtask

    task drive_write(axi4lite_transaction tr);

        @(negedge vif.aclk);

        vif.awaddr  = tr.addr;
        vif.awvalid = 1;
        vif.wdata   = tr.data;
        vif.wstrb   = tr.strb;
        vif.wvalid  = 1;
        vif.bready  = 1;

        fork

            begin
                do @(posedge vif.aclk);
                while (vif.awready !== 1'b1);

                @(negedge vif.aclk);
                vif.awvalid = 0;
            end

            begin
                do @(posedge vif.aclk);
                while (vif.wready !== 1'b1);

                @(negedge vif.aclk);
                vif.wvalid = 0;
            end

            begin
                do @(posedge vif.aclk);
                while (vif.bvalid !== 1'b1);

                tr.resp = vif.bresp;

                @(negedge vif.aclk);
                vif.bready = 0;
            end

            begin
                repeat (1000) @(posedge vif.aclk);
                `uvm_fatal("DRIVER", "AXI write timeout")
            end

        join_any

        // Wait for all three AXI write handshakes.
        wait (!vif.awvalid && !vif.wvalid && !vif.bready);

        disable fork;

        `uvm_info("DRIVER",
            $sformatf("WRITE addr=%h data=%h resp=%h",
                      tr.addr, tr.data, tr.resp),
            UVM_MEDIUM)

    endtask

    task drive_read(axi4lite_transaction tr);

        @(negedge vif.aclk);

        vif.araddr  = tr.addr;
        vif.arvalid = 1;
        vif.rready  = 1;

        fork

            begin
                do @(posedge vif.aclk);
                while (vif.arready !== 1'b1);

                @(negedge vif.aclk);
                vif.arvalid = 0;
            end

            begin
                do @(posedge vif.aclk);
                while (vif.rvalid !== 1'b1);

                tr.rdata = vif.rdata;
                tr.resp  = vif.rresp;

                @(negedge vif.aclk);
                vif.rready = 0;
            end

            begin
                repeat (1000) @(posedge vif.aclk);
                `uvm_fatal("DRIVER", "AXI read timeout")
            end

        join_any

        wait (!vif.arvalid && !vif.rready);

        disable fork;

        `uvm_info("DRIVER",
            $sformatf("READ addr=%h data=%h resp=%h",
                      tr.addr, tr.rdata, tr.resp),
            UVM_MEDIUM)

    endtask

endclass

`endif