`timescale 1ns / 1ps

import uvm_pkg::*;
import iic_pkg::*;

module tb_top;
    logic clk;
    logic resetn;
    logic reset_released;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_released = 1'b0;
        repeat (5) @(posedge clk);
        reset_released = 1'b1;
    end

    iic_if vif (
        .clk(clk),
        .resetn(resetn)
    );

    assign resetn  = reset_released && !vif.reset_req;
    assign vif.sda = vif.target_sda_drive_low ? 1'b0 : 1'bz;

    iic_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH (4)
    ) dut (
        .scl(vif.scl),
        .sda(vif.sda),
        .intr(vif.intr),

        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(resetn),
        .s00_axi_awaddr (vif.awaddr),
        .s00_axi_awprot (vif.awprot),
        .s00_axi_awvalid(vif.awvalid),
        .s00_axi_awready(vif.awready),
        .s00_axi_wdata  (vif.wdata),
        .s00_axi_wstrb  (vif.wstrb),
        .s00_axi_wvalid (vif.wvalid),
        .s00_axi_wready (vif.wready),
        .s00_axi_bresp  (vif.bresp),
        .s00_axi_bvalid (vif.bvalid),
        .s00_axi_bready (vif.bready),
        .s00_axi_araddr (vif.araddr),
        .s00_axi_arprot (vif.arprot),
        .s00_axi_arvalid(vif.arvalid),
        .s00_axi_arready(vif.arready),
        .s00_axi_rdata  (vif.rdata),
        .s00_axi_rresp  (vif.rresp),
        .s00_axi_rvalid (vif.rvalid),
        .s00_axi_rready (vif.rready)
    );

    rtl_iic_target_model target_model (
        .clk          (clk),
        .reset_n      (resetn),
        .scl          (vif.scl),
        .sda          (vif.sda),
        .own_addr     (vif.target_own_addr),
        .tx_data      (vif.target_tx_data),
        .ack_addr_en  (vif.target_ack_addr_en),
        .ack_data_en  (vif.target_ack_data_en),
        .sda_drive_low(vif.target_sda_drive_low),
        .rx_data      (vif.target_rx_data),
        .rx_valid     (vif.target_rx_valid),
        .addr_seen    (vif.target_addr_seen),
        .rw_seen      (vif.target_rw_seen),
        .start_count  (vif.target_start_count),
        .stop_count   (vif.target_stop_count)
    );

    initial begin
        uvm_config_db#(virtual iic_if)::set(null, "*", "vif", vif);
        run_test("");
    end
endmodule
