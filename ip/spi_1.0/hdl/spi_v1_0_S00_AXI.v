`timescale 1 ns / 1 ps

module spi_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // ── CTRL (slv_reg0 → spi_master_top) ─────────────────
    output wire       start,   // slv_reg0[0]    전송 시작 1클럭 펄스
    output wire       cpol,    // slv_reg0[2]    clock polarity
    output wire       cpha,    // slv_reg0[3]    clock phase
    output wire [1:0] cs_sel,  // slv_reg0[5:4]  슬레이브 선택
    output wire [7:0] clk_div, // slv_reg1[15:8] SCLK 분주값
    // done_ie = slv_reg0[1] → 내부에서 직접 사용

    // ── TX DATA (slv_reg1 → spi_master_top) ──────────────
    output wire [7:0] tx_data,  // slv_reg1[7:0]

    // ── STATUS (spi_master_top → slv_reg2) ───────────────
    input wire busy,  // slv_reg2[0]
    input wire done,  // 1클럭 펄스

    // ── RX DATA (spi_master_top → slv_reg3) ──────────────
    input wire [7:0] rx_data,  // done 시 래칭

    // ── 인터럽트 ──────────────────────────────────────────
    output wire intr,  // slv_reg0[1](done_ie) & done

    // ── AXI4-Lite 버스 ────────────────────────────────────
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,
    input  wire [  C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input  wire [                     2 : 0] S_AXI_AWPROT,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,
    input  wire [  C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,
    output wire [                     1 : 0] S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,
    input  wire [  C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input  wire [                     2 : 0] S_AXI_ARPROT,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,
    output wire [  C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [                     1 : 0] S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY
);

    // ── 주소 파라미터 (원본 템플릿 동일) ─────────────────
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    // ── AXI4-Lite 내부 신호 ───────────────────────────────
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;
    reg aw_en;

    wire slv_reg_wren;
    wire slv_reg_rden;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;

    // ── 슬레이브 레지스터 ─────────────────────────────────
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // 0x00 CTRL   (R/W)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // 0x04 TX DATA (W)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // 0x0C RX DATA (R, done 시 래칭)
    // slv_reg2 0x08 STATUS — 하드와이어 (busy, done), 레지스터 불필요

    reg start_r;  // start 1클럭 펄스

    // ── I/O assign ────────────────────────────────────────
    assign start   = start_r;
    assign cpol    = slv_reg0[2];
    assign cpha    = slv_reg0[3];
    assign cs_sel  = slv_reg0[5:4];
    assign clk_div = slv_reg0[15:8];
    assign tx_data = slv_reg1[7:0];
    assign intr    = slv_reg0[1] & done;   // done_ie & done 펄스

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // ── AW 채널: awready 생성 ─────────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_awready <= 1'b0;
                aw_en       <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // ── AW 채널: awaddr 래칭 ─────────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                axi_awaddr <= S_AXI_AWADDR;
        end
    end

    // ── W 채널: wready 생성 ──────────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
                axi_wready <= 1'b1;
            else axi_wready <= 1'b0;
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // ── 레지스터 쓰기 (byte strobe 지원, 원본 템플릿 구조 동일) ──
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0: begin  // CTRL
                        for (
                            byte_index = 0;
                            byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                            byte_index = byte_index + 1
                        )
                        if (S_AXI_WSTRB[byte_index])
                            slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        slv_reg0[0] <= 1'b0;  // start는 write-only 펄스, 저장 안 함
                    end
                    2'h1:  // TX DATA
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    // 2'h2: STATUS — read only, 쓰기 무시
                    // 2'h3: RX DATA — read only, 쓰기 무시
                    default: ;
                endcase
            end
        end
    end

    // ── start 1클럭 펄스 생성 ────────────────────────────
    // CTRL 레지스터에 WDATA[0]=1 로 쓰는 순간 1클럭만 HIGH
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            start_r <= 1'b0;
        end else begin
            start_r <= 1'b0;
            if (slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0)
                             && S_AXI_WDATA[0])
                start_r <= 1'b1;
        end
    end

    // ── RX DATA 래칭 (done 펄스 시) ──────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg3 <= 0;
        end else begin
            if (done) slv_reg3[7:0] <= rx_data;
        end
    end

    // ── B 채널: 쓰기 응답 ────────────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;  // OKAY
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // ── AR 채널: arready / araddr ────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // ── R 채널: rvalid ───────────────────────────────────
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // OKAY
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // ── 레지스터 읽기 ─────────────────────────────────────
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0: reg_data_out = slv_reg0;  // CTRL
            2'h1: reg_data_out = slv_reg1;  // TX DATA
            2'h2:
            reg_data_out = {30'b0, done, busy};  // STATUS (하드와이어)
            2'h3: reg_data_out = {24'b0, slv_reg3[7:0]};  // RX DATA
            default: reg_data_out = 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) axi_rdata <= 0;
        else if (slv_reg_rden) axi_rdata <= reg_data_out;
    end

endmodule
