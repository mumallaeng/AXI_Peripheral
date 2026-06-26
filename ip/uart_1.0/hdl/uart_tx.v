`timescale 1 ns / 1 ps

// UART 송신기 (8N1: 데이터 8비트, 패리티 없음, 정지비트 1비트)

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,  // 송신할 바이트
    input  wire       valid,    // 전송 시작 펄스 (1클럭 high)
    output reg        ready,    // idle 상태 (다음 데이터 수락 가능)
    output reg        tx        // 직렬 출력 라인
);

    // 한 비트 동안 카운트해야 하는 클럭 수
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // 송신 FSM 상태
    localparam S_IDLE = 2'd0;  // 대기
    localparam S_START = 2'd1;  // 시작비트(0) 출력
    localparam S_DATA = 2'd2;  // 데이터 8비트 출력
    localparam S_STOP = 2'd3;  // 정지비트(1) 출력

    reg [1:0] state;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;  // 비트 길이 카운터
    reg [2:0] bit_idx;  // 현재 송신 중인 비트 인덱스
    reg [7:0] shift_reg;  // 송신 데이터 보관

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            tx        <= 1'b1;  // idle 상태에서 라인은 high
            ready     <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;
                    if (valid) begin
                        // 데이터 캡처 후 시작비트로 진입
                        shift_reg <= data_in;
                        clk_cnt   <= 0;
                        ready     <= 1'b0;
                        state     <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;  // 시작비트
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shift_reg[bit_idx];  // LSB부터 차례로 전송
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;  // 정지비트
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
