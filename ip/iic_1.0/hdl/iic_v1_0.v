
`timescale 1 ns / 1 ps

module iic_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    inout  wire scl,
    inout  wire sda,
    output wire intr,

    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);
    wire ctrl_scl_drive_low;
    wire ctrl_sda_drive_low;

    // IIC open-drain output model
    // drive_low=1: drive 0, drive_low=0: high impedance (Z)
    assign scl = ctrl_scl_drive_low ? 1'b0 : 1'bz;
    assign sda = ctrl_sda_drive_low ? 1'b0 : 1'bz;

    // AXI register block -> IIC controller
    wire        start;
    wire        rw;
    wire        ack_in;
    wire [15:0] clk_div;
    wire [ 6:0] target_addr;
    wire [ 7:0] tx_data;

    // IIC controller -> AXI register block
    wire        busy;
    wire        done;
    wire        ack_seen;
    wire [ 7:0] rx_data;

    iic_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) iic_v1_0_S00_AXI_inst (
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready),
        .start        (start),
        .rw           (rw),
        .ack_in       (ack_in),
        .clk_div      (clk_div),
        .target_addr  (target_addr),
        .tx_data      (tx_data),
        .busy         (busy),
        .done         (done),
        .ack_seen     (ack_seen),
        .rx_data      (rx_data),
        .intr         (intr)
    );

    iic_controller iic_controller_inst (
        .clk               (s00_axi_aclk),
        .reset_n           (s00_axi_aresetn),
        .clk_div           (clk_div),
        .target_addr       (target_addr),
        .rw                (rw),
        .scl               (scl),
        .sda               (sda),
        .ctrl_scl_drive_low(ctrl_scl_drive_low),
        .ctrl_sda_drive_low(ctrl_sda_drive_low),
        .start             (start),
        .tx_data           (tx_data),
        .ack_in            (ack_in),
        .ack_seen          (ack_seen),
        .rx_data           (rx_data),
        .busy              (busy),
        .done              (done)
    );

endmodule
