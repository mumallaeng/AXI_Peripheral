`timescale 1 ns / 1 ps

// 기본 설정: 100 MHz 클럭, 115200 baud, 8N1 포맷

module uart_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    // TX 인터페이스
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_ready,
    output wire       tx,
    // RX 인터페이스
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_valid
);

    uart_tx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk    (clk),
        .rst_n  (rst_n),
        .data_in(tx_data),
        .valid  (tx_valid),
        .ready  (tx_ready),
        .tx     (tx)
    );

    uart_rx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk     (clk),
        .rst_n   (rst_n),
        .rx      (rx),
        .data_out(rx_data),
        .valid   (rx_valid)
    );

endmodule
