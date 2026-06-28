class spi_driver extends uvm_driver #(spi_seq_item); //
    `uvm_component_utils(spi_driver)

    virtual spi_if vif;

    // monitor가 소유한 analysis port를 agent에서 주입받아 broadcast
    uvm_analysis_port #(spi_seq_item) ap;

    // 레지스터 오프셋
    localparam bit [3:0] CTRL   = 4'h0;
    localparam bit [3:0] TXDATA = 4'h4;
    localparam bit [3:0] STATUS = 4'h8;
    localparam bit [3:0] RXDATA = 4'hC;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "vif를 config_db에서 찾지 못함")
    endfunction

    task run_phase(uvm_phase phase);
        // 초기화
        vif.drv_cb.awvalid <= 0; vif.drv_cb.wvalid <= 0; vif.drv_cb.bready <= 0;
        vif.drv_cb.arvalid <= 0; vif.drv_cb.rready <= 0;
        vif.drv_cb.awaddr  <= 0; vif.drv_cb.wdata  <= 0; vif.drv_cb.wstrb <= 4'hF;
        vif.drv_cb.araddr  <= 0; vif.drv_cb.slv_tx_byte <= 0;
        vif.drv_cb.slv_cpol <= 0; vif.drv_cb.slv_cpha <= 0;

        // 리셋 해제 대기
        wait (vif.resetn === 1'b1);
        @(vif.drv_cb);

        forever begin
            bit [31:0] ctrl_val;
            bit [31:0] rdat;
            seq_item_port.get_next_item(req);

            // 1) slave 모델이 보낼 바이트 + 모드 셋업
            vif.drv_cb.slv_tx_byte <= req.s_tx_data;
            vif.drv_cb.slv_cpol    <= req.cpol;
            vif.drv_cb.slv_cpha    <= req.cpha;
            @(vif.drv_cb);  // 모드 신호 안정화

            // 2) TXDATA write
            axi_write(TXDATA, {24'b0, req.m_tx_data});

            // 3) CTRL write = start. start[0]=1, done_ie[1]=0,
            //    cpol[2], cpha[3], cs_sel[5:4], clk_div[15:8]
            ctrl_val = 32'b0;
            ctrl_val[0]     = 1'b1;        // start 펄스
            ctrl_val[2]     = req.cpol;
            ctrl_val[3]     = req.cpha;
            ctrl_val[5:4]   = req.cs_sel;
            ctrl_val[15:8]  = req.clk_div;
            axi_write(CTRL, ctrl_val);

            // 4) busy 풀릴 때까지 STATUS 폴링 (busy=bit0)
            do begin
                axi_read(STATUS, rdat);
            end while (rdat[0] === 1'b1);
            // done=bit1 확인 (폴링 도중 떴을 수 있으니 한 번 더 안전 read)

            // 5) RXDATA read → master가 받은 값
            axi_read(RXDATA, rdat);
            req.m_rx_data = rdat[7:0];

            // 6) slave가 받은 값 캡처
            req.s_rx_byte = vif.drv_cb.slv_rx_byte;

            `uvm_info(get_type_name(), $sformatf("구동완료: %s", req.convert2string()), UVM_HIGH)
            if (ap != null) ap.write(req);
            seq_item_port.item_done();
        end
    endtask

    // ── AXI4-Lite write (검증된 핸드셰이크: ready 본 다음 클럭에 valid 내림) ──
    task automatic axi_write(input bit [3:0] addr, input bit [31:0] data);
        @(vif.drv_cb);
        vif.drv_cb.awaddr  <= addr;
        vif.drv_cb.awvalid <= 1'b1;
        vif.drv_cb.wdata   <= data;
        vif.drv_cb.wstrb   <= 4'hF;
        vif.drv_cb.wvalid  <= 1'b1;
        vif.drv_cb.bready  <= 1'b1;
        while (!(vif.drv_cb.awready && vif.drv_cb.wready)) @(vif.drv_cb);
        @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b0;
        vif.drv_cb.wvalid  <= 1'b0;
        while (!vif.drv_cb.bvalid) @(vif.drv_cb);
        @(vif.drv_cb);
        vif.drv_cb.bready <= 1'b0;
    endtask

    // ── AXI4-Lite read ─────────────────────────────────────
    task automatic axi_read(input bit [3:0] addr, output bit [31:0] data);
        @(vif.drv_cb);
        vif.drv_cb.araddr  <= addr;
        vif.drv_cb.arvalid <= 1'b1;
        vif.drv_cb.rready  <= 1'b1;
        while (!vif.drv_cb.arready) @(vif.drv_cb);
        @(vif.drv_cb);
        vif.drv_cb.arvalid <= 1'b0;
        while (!vif.drv_cb.rvalid) @(vif.drv_cb);
        data = vif.drv_cb.rdata;
        @(vif.drv_cb);
        vif.drv_cb.rready <= 1'b0;
    endtask
endclass