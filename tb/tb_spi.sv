`timescale 1ns / 1ps

module tb_spi ();

    // ── 클럭 / 리셋 ──────────────────────────────────────
    logic clk, reset_n;

    // ── 레지스터 섀도우 ───────────────────────────────────
    logic [31:0] CTRL, TDR, SR, RDR;

    // ── SPI 외부 핀 ───────────────────────────────────────
    logic sclk, sdo, sdi;
    logic [  3:0] cs_n;
    logic         intr;

    // ── AXI4-Lite 버스 ────────────────────────────────────
    logic         s00_axi_aclk;
    logic         s00_axi_aresetn;
    logic [  3:0] s00_axi_awaddr;
    logic [  2:0] s00_axi_awprot;
    logic         s00_axi_awvalid;
    logic         s00_axi_awready;
    logic [ 31:0] s00_axi_wdata;
    logic [  3:0] s00_axi_wstrb;
    logic         s00_axi_wvalid;
    logic         s00_axi_wready;
    logic [1 : 0] s00_axi_bresp;
    logic         s00_axi_bvalid;
    logic         s00_axi_bready;
    logic [  3:0] s00_axi_araddr;
    logic [  2:0] s00_axi_arprot;
    logic         s00_axi_arvalid;
    logic         s00_axi_arready;
    logic [ 31:0] s00_axi_rdata;
    logic [  1:0] s00_axi_rresp;
    logic         s00_axi_rvalid;
    logic         s00_axi_rready;

    // ── 레지스터 맵 주소 ──────────────────────────────────
    localparam SPI_CTRL_ADDR = 32'h0000_0000;  // 0x00 CTRL
    localparam SPI_TDR_ADDR = 32'h0000_0004;  // 0x04 TX DATA
    localparam SPI_SR_ADDR = 32'h0000_0008;  // 0x08 STATUS
    localparam SPI_RDR_ADDR = 32'h0000_000C;  // 0x0C RX DATA

    // ── DUT ──────────────────────────────────────────────
    spi_v1_0 dut (
        .s00_axi_aclk   (s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready),
        .sclk (sclk),
        .sdo (sdo),
        .sdi (sdi),
        .cs_n (cs_n),
        .intr (intr)
    );

    // ── loopback: sdi = sdo ─────────────────────────────
    assign sdi = sdo;

    assign s00_axi_aclk    = clk;
    assign s00_axi_aresetn = reset_n;

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // ── AXI Write task (UART 테베 동일) ──────────────────
    task automatic AXI_WriteData(logic [31:0] addr, logic [31:0] data);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;
        @(posedge clk);
        wait (s00_axi_awready & s00_axi_wready) @(posedge clk);
        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;
        @(posedge clk);
        wait (s00_axi_bvalid);
        @(posedge clk);
        s00_axi_bready <= 1'b0;
        @(posedge clk);
    endtask

    // ── AXI Read task (UART 테베 동일) ───────────────────
    task automatic AXI_ReadData(input logic [31:0] addr,
                                output logic [31:0] rdata);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;
        @(posedge clk);
        wait (s00_axi_arready);
        @(posedge clk);
        s00_axi_arvalid <= 1'b0;
        wait (s00_axi_rvalid);
        @(posedge clk);
        s00_axi_rready <= 1'b0;
        rdata = s00_axi_rdata;
        @(posedge clk);
    endtask

    // ── SPI 전송 task (TX 쓰기 + start 펄스) ─────────────
    task automatic SPI_Send(logic [7:0] data);
        // TX DATA 먼저 쓰기
        AXI_WriteData(SPI_TDR_ADDR, {24'b0, data});
        // CTRL[0]=1 로 start 펄스 발생 (done_ie, cpol, cpha, cs_sel, clk_div 유지)
        AXI_WriteData(SPI_CTRL_ADDR, CTRL | 32'h0000_0001);
    endtask

    // ── 메인 시나리오 ─────────────────────────────────────
    initial begin
        // 초기화
        reset_n         = 0;
        CTRL            = 0;
        TDR             = 0;
        SR              = 0;
        RDR             = 0;
        s00_axi_awvalid = 0;
        s00_axi_wvalid  = 0;
        s00_axi_bready  = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 0;

        repeat (5) @(posedge clk);
        reset_n = 1;
        @(posedge clk);

        // ── CTRL 설정 ──────────────────────────────────────
        // clk_div=4 (SCLK=10MHz@100MHz), cs_sel=0, cpol=0, cpha=0, done_ie=0
        CTRL = 32'h0000_0400;  // [15:8]=4, [1]=0(done_ie off)
        AXI_WriteData(SPI_CTRL_ADDR, CTRL);

        // ══ 폴링 방식 전송 ══════════════════════════════
        $display("=== 폴링 방식 전송 시작 ===");

        // 전송 1: 0xAA
        SPI_Send(8'hAA);
        do begin
            AXI_ReadData(SPI_SR_ADDR, SR);
        end while (SR[0]);  // busy가 내려갈 때까지 대기
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0xAA  RX=0x%02X (기대값: 0xAA)", RDR[7:0]);

        // 전송 2: 0x55
        SPI_Send(8'h55);
        do begin
            AXI_ReadData(SPI_SR_ADDR, SR);
        end while (SR[0]);
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0x55  RX=0x%02X (기대값: 0x55)", RDR[7:0]);

        // 전송 3: 0x12
        SPI_Send(8'h12);
        do begin
            AXI_ReadData(SPI_SR_ADDR, SR);
        end while (SR[0]);
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0x12  RX=0x%02X (기대값: 0x12)", RDR[7:0]);

        // ══ 인터럽트 방식 전송 ══════════════════════════
        $display("=== 인터럽트 방식 전송 시작 ===");

        // done_ie = 1 로 CTRL 업데이트
        CTRL = CTRL | 32'h0000_0002;  // [1]=1 (done_ie)
        AXI_WriteData(SPI_CTRL_ADDR, CTRL);

        // 전송 4: 0x34
        SPI_Send(8'h34);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0x34  RX=0x%02X (기대값: 0x34)", RDR[7:0]);

        // 전송 5: 0x11
        SPI_Send(8'h11);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0x11  RX=0x%02X (기대값: 0x11)", RDR[7:0]);

        // 전송 6: 0x22
        SPI_Send(8'h22);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(SPI_RDR_ADDR, RDR);
        $display("TX=0x22  RX=0x%02X (기대값: 0x22)", RDR[7:0]);

        #1000;
        $display("=== 시뮬레이션 완료 ===");
        $finish;
    end

endmodule
