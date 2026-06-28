`timescale 1ns / 1ps
// ============================================================
//  spi_controller  (방법 A — 엣지 검출 기반 재설계)
//  4모드(CPOL/CPHA) 전부, 전 clk_div 범위에서 정상 동작.
//
//  설계 원칙:
//   - half_tick마다 sclk_r 토글. 토글로 만들어지는 엣지가
//     leading/trailing 인지 (직전 sclk_r 값 + cpol)로 판별.
//   - 표준 SPI 규약:
//       CPHA=0: leading에서 샘플, trailing에서 다음 비트 출력
//       CPHA=1: leading에서 다음 비트 출력, trailing에서 샘플
//     leading 방향: CPOL=0 → rising, CPOL=1 → falling
//   - 샘플은 raw sdi. trailing/leading 샘플 모두 sclk 안정 구간이라
//     동기화기 지연 없이 위상 정렬됨.
//   - bit_cnt는 '샘플 발생' 기준으로 증가. 8번째 샘플 직후 STOP.
// ============================================================

module spi_controller (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       start,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [7:0] clk_div,
    input  logic [1:0] cs_sel,
    input  logic [7:0] tx_data,
    output logic       busy,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       sclk,
    output logic       sdo,
    input  logic       sdi,
    output logic [3:0] cs_n
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
    logic       [3:0] sample_cnt;  // 샘플한 비트 수 (0~8)
    logic             cpol_r;
    logic             cpha_r;
    logic             sclk_r;
    logic       [1:0] cs_sel_r;
    logic       [3:0] cs_n_r;

    // sdi 입력 동기화 (메타스태빌리티 방지). 샘플은 raw 사용하되
    // 동기화 레지스터도 유지(FPGA 안전성). 여기선 raw sdi 직접 샘플.
    logic sdi_sync0, sdi_sync;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sdi_sync0 <= 1'b0;
            sdi_sync  <= 1'b0;
        end else begin
            sdi_sync0 <= sdi;
            sdi_sync  <= sdi_sync0;
        end
    end

    assign sclk = sclk_r;
    assign cs_n = cs_n_r;

    function automatic logic [3:0] cs_decode;
        input logic [1:0] sel;
        input logic active;
        begin
            if (active) cs_decode = ~(4'b0001 << sel);
            else cs_decode = 4'b1111;
        end
    endfunction

    // 클럭 분주 (half_tick 생성)
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

    // 메인 FSM
    // 엣지 판별:
    //   sclk_r이 토글되기 직전 값(sclk_r)과 cpol로 leading/trailing 결정.
    //   half_tick 시 next_sclk = ~sclk_r.
    //   leading 엣지 = idle레벨(cpol)에서 벗어나는 방향의 엣지.
    //     CPOL=0: idle=0, leading=rising(0→1), trailing=falling(1→0)
    //     CPOL=1: idle=1, leading=falling(1→0), trailing=rising(0→1)
    //   즉 'leading'은 sclk_r==cpol_r 인 상태에서 토글될 때.

    logic is_leading;
    assign is_leading = (sclk_r == cpol_r);  // 현재 idle레벨이면 다음 토글이 leading

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state        <= IDLE;
            sdo          <= 1'b1;
            cs_n_r       <= 4'b1111;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            sample_cnt   <= 0;
            sclk_r       <= 1'b0;
            cpol_r       <= 1'b0;
            cpha_r       <= 1'b0;
            clk_div_r    <= 0;
            cs_sel_r     <= 0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    sdo <= 1'b1;
                    cs_n_r <= 4'b1111;
                    sclk_r <= cpol;
                    if (start) begin
                        state        <= START;
                        cpol_r       <= cpol;
                        cpha_r       <= cpha;
                        clk_div_r    <= clk_div;
                        tx_shift_reg <= tx_data;
                        cs_sel_r     <= cs_sel;
                        sample_cnt   <= 0;
                        sclk_r       <= cpol;  // idle 레벨
                        busy         <= 1'b1;
                        cs_n_r       <= cs_decode(cs_sel, 1'b1);
                    end
                end

                START: begin
                    // CPHA=0: 첫 비트는 CS assert 직후(첫 leading 전)에 출력돼야 함
                    if (cpha_r == 1'b0) begin
                        sdo          <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end

                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;

                        if (is_leading) begin
                            // ── leading 엣지 ──
                            if (cpha_r == 1'b0) begin
                                // CPHA0: leading에서 샘플
                                rx_shift_reg <= {rx_shift_reg[6:0], sdi};
                                sample_cnt   <= sample_cnt + 1;
                            end else begin
                                // CPHA1: leading에서 다음 비트 출력
                                sdo          <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin
                            // ── trailing 엣지 ──
                            if (cpha_r == 1'b0) begin
                                // CPHA0: trailing에서 다음 비트 출력
                                // (마지막 비트 출력은 불필요하지만 무해)
                                sdo          <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end else begin
                                // CPHA1: trailing에서 샘플
                                rx_shift_reg <= {rx_shift_reg[6:0], sdi};
                                sample_cnt   <= sample_cnt + 1;
                            end
                        end

                        // 8비트 모두 샘플 완료되면 종료
                        // (이 half_tick에서 샘플이 일어났고 그게 8번째이면)
                        if (((cpha_r == 1'b0) && is_leading && (sample_cnt == 7)) ||
                            ((cpha_r == 1'b1) && !is_leading && (sample_cnt == 7))) begin
                            state   <= STOP;
                            rx_data <= {rx_shift_reg[6:0], sdi};
                        end
                    end
                end

                STOP: begin
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    cs_n_r  <= 4'b1111;
                    sclk_r  <= cpol_r;
                    sdo    <= 1'b1;
                    state   <= IDLE;
                    sample_cnt <= 0;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
