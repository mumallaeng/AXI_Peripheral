`timescale 1ns / 1ps

module spi_master (
    // global signals
    input logic clk,
    input logic reset_n,
    // control signals
    input logic start,  // 1클럭 펄스: 전송 시작
    input logic cpol,  // SPI clock polarity
    input logic cpha,  // SPI clock phase
    input logic [7:0] clk_div,  // SCLK = clk / (2*(clk_div+1))
    input logic [1:0] cs_sel,  // 슬레이브 선택 (0~3)
    input  logic [7:0]  tx_data,        // 전송 데이터 (start 전에 유효해야 함)
    output logic busy,  // 전송 중 HIGH
    output logic [7:0] rx_data,  // 수신 데이터 (done 후 유효)
    output logic done,  // 전송 완료 1클럭 펄스
    // external SPI signals
    output logic sclk,
    output logic mosi,
    input logic miso,
    output logic [3:0] ss_n  // Chip Select, active low (4개)
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } spi_state_e;

    spi_state_e       state;

    logic       [7:0] div_cnt;
    logic       [7:0] clk_div_r;
    logic             half_tick;
    logic       [7:0] tx_shift_reg;
    logic       [7:0] rx_shift_reg;
    logic       [2:0] bit_cnt;
    logic             step;
    logic             cpol_r;
    logic             cpha_r;
    logic             sclk_r;
    logic       [1:0] cs_sel_r;
    logic       [3:0] ss_n_r;

    // ── 2단 동기화기 (miso 메타스태빌리티 방지) ──────────
    logic miso_sync0, miso_sync;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            miso_sync0 <= 1'b0;
            miso_sync  <= 1'b0;
        end else begin
            miso_sync0 <= miso;
            miso_sync  <= miso_sync0;
        end
    end

    assign sclk = sclk_r;
    assign ss_n = ss_n_r;

    // CS 디코더 (active low)
    function automatic logic [3:0] cs_decode;
        input logic [1:0] sel;
        input logic active;
        begin
            if (active) cs_decode = ~(4'b0001 << sel);
            else cs_decode = 4'b1111;
        end
    endfunction

    // ── 클럭 분주 (half_tick 생성) ───────────────────────
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div_r) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end else begin
                div_cnt   <= 0;
                half_tick <= 1'b0;
            end
        end
    end

    // ── 메인 FSM ─────────────────────────────────────────
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            ss_n_r       <= 4'b1111;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            bit_cnt      <= 0;
            step         <= 1'b0;
            sclk_r       <= 1'b0;
            cpol_r       <= 1'b0;
            cpha_r       <= 1'b0;
            clk_div_r    <= 0;
            cs_sel_r     <= 0;
        end else begin
            done <= 1'b0;  // done은 1사이클 펄스

            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    ss_n_r <= 4'b1111;
                    sclk_r <= cpol;
                    if (start) begin
                        state        <= START;
                        cpol_r       <= cpol;
                        cpha_r       <= cpha;
                        clk_div_r    <= clk_div;
                        tx_shift_reg <= tx_data;
                        cs_sel_r     <= cs_sel;
                        bit_cnt      <= 0;
                        step         <= 1'b0;
                        busy         <= 1'b1;
                        ss_n_r       <= cs_decode(cs_sel, 1'b1);
                    end
                end

                START: begin
                    // CPHA=0: CS assert 직후 첫 비트 출력
                    if (cpha_r == 1'b0) begin
                        mosi         <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end

                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 0) begin  // 첫 번째 엣지
                            step <= 1'b1;
                            if (cpha_r == 1'b0)
                                rx_shift_reg <= {
                                    rx_shift_reg[6:0], miso_sync
                                };  // 동기화된 miso 샘플링
                            else begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin  // 두 번째 엣지
                            step <= 1'b0;
                            if (cpha_r == 1'b0) begin
                                if (bit_cnt < 7) begin
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                            end else
                                rx_shift_reg <= {
                                    rx_shift_reg[6:0], miso_sync
                                };  // 동기화된 miso 샘플링

                            if (bit_cnt == 7) begin
                                state <= STOP;
                                rx_data <= (cpha_r == 1'b0) ? rx_shift_reg
                                                             : {rx_shift_reg[6:0], miso_sync};
                            end else bit_cnt <= bit_cnt + 1;
                        end
                    end
                end

                STOP: begin
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    ss_n_r  <= 4'b1111;
                    sclk_r  <= cpol_r;
                    mosi    <= 1'b1;
                    state   <= IDLE;
                    bit_cnt <= 0;
                    step    <= 1'b0;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
