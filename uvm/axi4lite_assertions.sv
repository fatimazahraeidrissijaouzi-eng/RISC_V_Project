`timescale 1ns/1ps

module axi4lite_assertions(axi4lite_if vif);

    // ==========================================
    // WRITE ADDRESS CHANNEL
    // ==========================================

    property p_aw_stable;
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.awvalid && !vif.awready
        |=> vif.awvalid && $stable(vif.awaddr);
    endproperty

    A_AW_STABLE: assert property (p_aw_stable)
        else $error("SVA: AW channel violation");

    // ==========================================
    // WRITE DATA CHANNEL
    // ==========================================

    property p_w_stable;
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.wvalid && !vif.wready
        |=> vif.wvalid &&
            $stable(vif.wdata) &&
            $stable(vif.wstrb);
    endproperty

    A_W_STABLE: assert property (p_w_stable)
        else $error("SVA: W channel violation");

    // ==========================================
    // WRITE RESPONSE CHANNEL
    // ==========================================

    property p_b_stable;
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.bvalid && !vif.bready
        |=> vif.bvalid && $stable(vif.bresp);
    endproperty

    A_B_STABLE: assert property (p_b_stable)
        else $error("SVA: B channel violation");

    // ==========================================
    // READ ADDRESS CHANNEL
    // ==========================================

    property p_ar_stable;
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.arvalid && !vif.arready
        |=> vif.arvalid && $stable(vif.araddr);
    endproperty

    A_AR_STABLE: assert property (p_ar_stable)
        else $error("SVA: AR channel violation");

    // ==========================================
    // READ DATA CHANNEL
    // ==========================================

    property p_r_stable;
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.rvalid && !vif.rready
        |=> vif.rvalid &&
            $stable(vif.rdata) &&
            $stable(vif.rresp);
    endproperty

    A_R_STABLE: assert property (p_r_stable)
        else $error("SVA: R channel violation");

    // ==========================================
    // VALID RESPONSE CODES
    // ==========================================

    A_BRESP_VALID: assert property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.bvalid |->
        (vif.bresp inside {2'b00, 2'b10, 2'b11})
    ) else $error("SVA: Invalid BRESP");

    A_RRESP_VALID: assert property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.rvalid |->
        (vif.rresp inside {2'b00, 2'b10, 2'b11})
    ) else $error("SVA: Invalid RRESP");

    // ==========================================
    // ASSERTION COVERAGE
    // ==========================================

    C_AW_WAIT: cover property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.awvalid && !vif.awready
    );

    C_W_WAIT: cover property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.wvalid && !vif.wready
    );

    C_B_WAIT: cover property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.bvalid && !vif.bready
    );

    C_AR_WAIT: cover property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.arvalid && !vif.arready
    );

    C_R_WAIT: cover property (
        @(posedge vif.aclk)
        disable iff (!vif.aresetn)
        vif.rvalid && !vif.rready
    );

    initial begin
        $display("SVA: AXI4-Lite assertions enabled");
    end

endmodule