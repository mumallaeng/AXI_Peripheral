`timescale 1ns / 1ps
import uvm_pkg::*;
import spi_pkg::*;

module tb_top ();
    logic clk;
    logic resetn;

    // 클럭/리셋
    initial begin
        clk = 0;
        resetn = 0;
        repeat (5) @(posedge clk);
        resetn = 1;
    end
    always #5 clk = ~clk;

    // interface
    spi_if vif (
        .clk(clk),
        .resetn(resetn)
    );

    // ── DUT: AXI SPI Controller ────────────────────────────
    spi_controller_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) dut (
        .sclk(vif.sclk),
        .sdo (vif.sdo),
        .sdi (vif.sdi),
        .cs_n(vif.cs_n),
        .intr(vif.intr),

        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(resetn),
        .s00_axi_awaddr (vif.awaddr),
        .s00_axi_awprot (3'b000),
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
        .s00_axi_arprot (3'b000),
        .s00_axi_arvalid(vif.arvalid),
        .s00_axi_arready(vif.arready),
        .s00_axi_rdata  (vif.rdata),
        .s00_axi_rresp  (vif.rresp),
        .s00_axi_rvalid (vif.rvalid),
        .s00_axi_rready (vif.rready)
    );

    // ── TB SPI slave 모델 ──────────────────────────────────
    //  driver가 cs_sel을 바꾸므로, 활성화된 cs_n 비트를 모델에 전달.
    //  4개 slave 중 현재 선택된 것만 미소 구동하도록 결합.
    //  간단화를 위해 cpol/cpha/tx_byte는 driver가 vif로 공급.
    //  cs_n은 4비트 중 하나가 0 → 그 라인을 사용.
    // 4개 cs_n 중 하나라도 active(0)이면 통합 cs로 slave 모델에 전달
    wire ss_to_slave = &vif.cs_n;  // 모두 1이면 1(비활성), 하나라도 0이면 0(활성)

    // cpol/cpha는 CTRL 레지스터 값이 핀엔 없으므로 vif로 전달받음.
    spi_target_model u_slave (
        .sclk   (vif.sclk),
        .sdi    (vif.sdo),
        .sdo    (vif.sdi),
        .cs_n   (ss_to_slave),
        .cpol   (vif.slv_cpol),
        .cpha   (vif.slv_cpha),
        .tx_byte(vif.slv_tx_byte),
        .rx_byte(vif.slv_rx_byte)
    );

    // UVM 시작
    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
        run_test("");
    end

    initial begin
        $fsdbDumpfile("spi_axi_tb.fsdb");
        $fsdbDumpvars(0);
    end
endmodule
