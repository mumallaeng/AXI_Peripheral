
`timescale 1 ns / 1 ps

module spi_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi target Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line
    // ── 외부 SPI 핀
    output wire       sclk,
    output wire       sdo,
    input  wire       sdi,
    output wire [3:0] cs_n,  // active low, 4개

    // ── 인터럽트 
    output wire intr,  // done_ie & done_flag

    // Ports of Axi target Bus Interface S00_AXI
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

    wire       start;  // [0]
    wire       cpol;  // [2]
    wire       cpha;  // [3]
    wire [1:0] cs_sel;  // [5:4]
    wire [7:0] clk_div;  // [15:8]
    wire [7:0] tx_data;  // [7:0]
    wire       busy;  // [0]
    wire       done;  // [1] → 래퍼에서 done_flag로 래칭
    wire [7:0] rx_data;  // [7:0]


    // Instantiation of Axi Bus Interface S00_AXI
    spi_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) spi_v1_0_S00_AXI_inst (
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
        // SPI 제어 신호
        .start  (start),
        .cpol   (cpol),
        .cpha   (cpha),
        .cs_sel (cs_sel),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .busy   (busy),
        .done   (done),
        .rx_data(rx_data),
        .intr   (intr)
    );



    // Add user logic here
    spi_controller_top U_SPI_CON (
        .clk(s00_axi_aclk),
        .rst(s00_axi_aresetn),
        .start(start),  // [0]
        .cpol(cpol),  // [2]
        .cpha(cpha),  // [3]
        .cs_sel(cs_sel),  // [5:4]
        .clk_div(clk_div),  // [15:8]
        .tx_data(tx_data),  // [7:0]
        .busy(busy),  // [0]
        .done(done),  // [1] → 래퍼에서 done_flag로 래칭
        .rx_data(rx_data),  // [7:0]
        .sclk(sclk),
        .sdo(sdo),
        .sdi(sdi),
        .cs_n(cs_n)  // active low, 4개
    );
    // User logic ends

endmodule
