`timescale 1ns / 1ps
// ============================================================
//  spi_target_model  (TB 전용, 비합성) — single-driver, race-free
//  표준 SPI target. CPOL/CPHA 4모드. full-duplex 8bit, MSB first.
//
//  CPHA=0: CS assert 시 MSB를 미리 노출, trailing에서 다음 비트.
//          master는 leading에서 샘플.
//  CPHA=1: CS assert 시엔 출력 미정. 첫 leading에서 MSB 출력,
//          이후 trailing에서 샘플 / leading에서 다음 비트.
//
//  단일 always 프로세스 + non-blocking으로 다중구동/race 제거.
// ============================================================
module spi_target_model (
    input  logic       sclk,
    input  logic       sdi,
    output logic       sdo,
    input  logic       cs_n,
    input  logic       cpol,
    input  logic       cpha,
    input  logic [7:0] tx_byte,
    output logic [7:0] rx_byte
);

    logic [7:0] shift_tx;
    logic [7:0] shift_rx;
    logic       sdo_r;
    logic       cs_n_q;
    logic       sclk_q;

    assign sdo = cs_n ? 1'bz : sdo_r;

    always @(cs_n or sclk) begin
        // ── CS assert (negedge cs_n) ──
        if (cs_n_q == 1'b1 && cs_n == 1'b0) begin
            shift_rx <= 8'h00;
            if (cpha == 1'b0) begin
                // CPHA0: MSB 미리 노출, 나머지 대기
                sdo_r   <= tx_byte[7];
                shift_tx <= {tx_byte[6:0], 1'b0};
            end else begin
                // CPHA1: 아직 출력 안 함. 전체를 shift_tx에 보관.
                sdo_r   <= 1'b0;
                shift_tx <= tx_byte;
            end
        end  // ── sclk 엣지 (CS 활성 중) ──
        else if (!cs_n && (sclk !== sclk_q)) begin
            bit is_neg, leading;
            is_neg  = (sclk == 1'b0);
            leading = (cpol == 1'b0) ? (is_neg == 1'b0) : (is_neg == 1'b1);
            if (leading) begin
                if (cpha == 1'b0) begin
                    // CPHA0 leading: 샘플
                    shift_rx <= {shift_rx[6:0], sdi};
                    rx_byte  <= {shift_rx[6:0], sdi};
                end else begin
                    // CPHA1 leading: 다음 비트 출력 (첫 leading이면 MSB)
                    sdo_r   <= shift_tx[7];
                    shift_tx <= {shift_tx[6:0], 1'b0};
                end
            end else begin
                if (cpha == 1'b0) begin
                    // CPHA0 trailing: 다음 비트 출력
                    sdo_r   <= shift_tx[7];
                    shift_tx <= {shift_tx[6:0], 1'b0};
                end else begin
                    // CPHA1 trailing: 샘플
                    shift_rx <= {shift_rx[6:0], sdi};
                    rx_byte  <= {shift_rx[6:0], sdi};
                end
            end
        end
        cs_n_q <= cs_n;
        sclk_q <= sclk;
    end

    initial begin
        rx_byte  = 8'h00;
        shift_tx = 8'h00;
        shift_rx = 8'h00;
        sdo_r   = 1'b1;
        cs_n_q   = 1'b1;
        sclk_q   = 1'b0;
    end

endmodule
