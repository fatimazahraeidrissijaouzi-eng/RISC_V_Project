`ifndef AXI4LITE_MONITOR_SV
`define AXI4LITE_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi4lite_transaction.sv"

class axi4lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi4lite_monitor)

    virtual axi4lite_if vif;

    uvm_analysis_port #(axi4lite_transaction) ap;

    function new(string name = "axi4lite_monitor",
                 uvm_component parent = null);

        super.new(name, parent);
        ap = new("ap", this);

    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db#(virtual axi4lite_if)::get(
            this, "", "vif", vif))
            `uvm_fatal("MONITOR", "Virtual interface not found")

    endfunction

    task run_phase(uvm_phase phase);

        fork
            monitor_write();
            monitor_read();
        join

    endtask

    task monitor_write();

        axi4lite_transaction tr;
        bit aw_seen = 0;
        bit w_seen  = 0;

        tr = axi4lite_transaction::type_id::create("wr");

        forever begin

            @(posedge vif.aclk);

            if (vif.aresetn !== 1'b1) begin

                aw_seen = 0;
                w_seen  = 0;
                tr = axi4lite_transaction::type_id::create("wr");

            end else begin

                if (vif.awvalid && vif.awready) begin
                    tr.addr = vif.awaddr;
                    aw_seen = 1;
                end

                if (vif.wvalid && vif.wready) begin
                    tr.data = vif.wdata;
                    tr.strb = vif.wstrb;
                    w_seen = 1;
                end

                if (vif.bvalid && vif.bready) begin

                    if (aw_seen && w_seen) begin

                        tr.write = 1;
                        tr.resp  = vif.bresp;

                        ap.write(tr);

                        `uvm_info("MONITOR",
                            $sformatf(
                            "WRITE addr=%h data=%h resp=%h",
                            tr.addr, tr.data, tr.resp),
                            UVM_MEDIUM)

                    end else begin

                        `uvm_error("MONITOR",
                            "Unexpected write response")

                    end

                    aw_seen = 0;
                    w_seen  = 0;

                    tr = axi4lite_transaction::type_id::create("wr");

                end

            end

        end

    endtask

    task monitor_read();

        axi4lite_transaction tr;
        bit ar_seen = 0;

        tr = axi4lite_transaction::type_id::create("rd");

        forever begin

            @(posedge vif.aclk);

            if (vif.aresetn !== 1'b1) begin

                ar_seen = 0;
                tr = axi4lite_transaction::type_id::create("rd");

            end else begin

                if (vif.arvalid && vif.arready) begin
                    tr.addr = vif.araddr;
                    ar_seen = 1;
                end

                if (vif.rvalid && vif.rready) begin

                    if (ar_seen) begin

                        tr.write = 0;
                        tr.rdata = vif.rdata;
                        tr.resp  = vif.rresp;

                        ap.write(tr);

                        `uvm_info("MONITOR",
                            $sformatf(
                            "READ addr=%h data=%h resp=%h",
                            tr.addr, tr.rdata, tr.resp),
                            UVM_MEDIUM)

                    end else begin

                        `uvm_error("MONITOR",
                            "Unexpected read response")

                    end

                    ar_seen = 0;

                    tr = axi4lite_transaction::type_id::create("rd");

                end

            end

        end

    endtask

endclass

`endif