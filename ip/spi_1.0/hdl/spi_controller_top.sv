`timescale 1ns / 1ps

// ============================================================
//  spi_controller_top
//  AXI4-Lite 래퍼와 spi_controller 코어 사이의 인터페이스 모듈.
//  래퍼에서 target_reg 비트를 이 모듈의 포트로 연결한다.
// ============================================================
//
//  [ 레지스터 맵 ]
//
//  offset  name      R/W  비트 필드
//  ------  --------  ---  -------------------------------------------
//  0x00    CTRL      R/W  [0]     start   : 전송 시작 펄스 (래퍼 자동 생성)
//                         [1]     done_ie : 인터럽트 인에이블 (래퍼에서 직접 처리)
//                         [2]     cpol    : SPI clock polarity
//                         [3]     cpha    : SPI clock phase
//                         [5:4]   cs_sel  : target 선택 (0~3)
//                         [7:6]   reserved
//                         [15:8]  clk_div : SCLK = clk / (2*(clk_div+1))
//                         [31:16] reserved
//
//  0x04    TX DATA   W    [7:0]   tx_data : 전송 데이터 (start 전에 유효)
//
//  0x08    STATUS    R    [0]     busy      : 전송 중 HIGH
//                         [1]     done_flag : 완료 래치 (0x0C 읽으면 클리어)
//
//  0x0C    RX DATA   R    [7:0]   rx_data : 수신 데이터
//
//  intr = CTRL[1] (done_ie) & STATUS[1] (done_flag)
// ============================================================

module spi_controller_top (
    input clk,
    input rst,

    // ── CTRL (target_reg0) ──────────────────────────────────
    input       start,   // [0]
    input       cpol,    // [2]
    input       cpha,    // [3]
    input [1:0] cs_sel,  // [5:4]
    input [7:0] clk_div, // [15:8]

    // ── TX DATA (target_reg1) ───────────────────────────────
    input [7:0] tx_data,  // [7:0]

    // ── STATUS (target_reg2) ────────────────────────────────
    output busy,  // [0]
    output done,  // [1] → 래퍼에서 done_flag로 래칭

    // ── RX DATA (target_reg3) ───────────────────────────────
    output [7:0] rx_data,  // [7:0]

    // ── 외부 SPI 핀 ──────────────────────────────────────
    output       sclk,
    output       sdo,
    input        sdi,
    output [3:0] cs_n   // active low, 4개
);

    spi_controller u_spi_controller (
        .clk    (clk),
        .reset_n(rst),
        .start  (start),
        .cpol   (cpol),
        .cpha   (cpha),
        .clk_div(clk_div),
        .cs_sel (cs_sel),
        .tx_data(tx_data),
        .busy   (busy),
        .rx_data(rx_data),
        .done   (done),
        .sclk   (sclk),
        .sdo   (sdo),
        .sdi   (sdi),
        .cs_n   (cs_n)
    );

    // intr = target_reg0[1] (done_ie) & done_flag
    // → AXI wrapper 내부에서 생성. 이 모듈은 관여하지 않음.

endmodule
