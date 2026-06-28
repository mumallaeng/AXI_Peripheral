`timescale 1ns / 1ps

interface iic_if (
    input logic clk,
    input logic resetn
);
    logic [3:0]  awaddr;
    logic [2:0]  awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    logic [3:0]  araddr;
    logic [2:0]  arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    tri1 scl;
    tri1 sda;
    logic intr;
    logic reset_req;

    logic       target_sda_drive_low;
    logic [6:0] target_own_addr;
    logic [7:0] target_tx_data;
    logic       target_ack_addr_en;
    logic       target_ack_data_en;
    logic [7:0] target_rx_data;
    logic       target_rx_valid;
    logic [7:0] target_addr_seen;
    logic       target_rw_seen;
    logic [7:0] target_start_count;
    logic [7:0] target_stop_count;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
        output araddr, arprot, arvalid, rready;
        output reset_req;
        output target_own_addr, target_tx_data, target_ack_addr_en, target_ack_data_en;
        input awready, wready, bresp, bvalid;
        input arready, rdata, rresp, rvalid;
        input intr, target_rx_data, target_rx_valid, target_addr_seen, target_rw_seen;
        input target_start_count, target_stop_count;
    endclocking

    modport DRV(clocking drv_cb, input clk, input resetn);
endinterface
