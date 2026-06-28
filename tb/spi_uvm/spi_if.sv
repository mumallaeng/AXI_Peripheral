`timescale 1ns / 1ps
// AXI4-Lite + SPI 외부핀을 모두 담는 interface
interface spi_if (  //
    input logic clk,
    input logic resetn  // active-low (AXI aresetn과 동일)
);
    // ── AXI4-Lite ──────────────────────────────────────
    logic [3:0] awaddr;
    logic awvalid;
    logic awready;
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wvalid;
    logic wready;
    logic [1:0] bresp;
    logic bvalid;
    logic bready;
    logic [3:0] araddr;
    logic arvalid;
    logic arready;
    logic [31:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;

    // ── SPI 외부핀 / 인터럽트 (모니터링용) ───────────────
    logic sclk;
    logic sdo;
    logic sdi;
    logic [3:0] cs_n;
    logic intr;

    // ── TB slave 모델 제어 (드라이버가 셋업) ─────────────
    //  실제 핀은 아니지만 slave 모델로 보낼 데이터 / 받은 데이터
    logic [7:0] slv_tx_byte;  // slave가 master로 보낼 값
    logic [7:0]  slv_rx_byte;   // slave가 master로부터 받은 값 (모델 출력)
    logic slv_cpol;  // slave 모델에 알려줄 cpol
    logic slv_cpha;  // slave 모델에 알려줄 cpha

    // driver용 clocking block (AXI 마스터 구동)
    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output awaddr, awvalid, wdata, wstrb, wvalid, bready;
        output araddr, arvalid, rready;
        output slv_tx_byte, slv_cpol, slv_cpha;
        input awready, wready, bresp, bvalid;
        input arready, rdata, rresp, rvalid;
        input intr, slv_rx_byte;
    endclocking

    modport DRV(clocking drv_cb, input clk, input resetn);
endinterface
