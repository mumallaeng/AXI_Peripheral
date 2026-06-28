class iic_driver extends uvm_driver #(iic_seq_item);
    `uvm_component_utils(iic_driver)

    virtual iic_if vif;
    uvm_analysis_port #(iic_seq_item) expected_ap;

    localparam bit [3:0] CTRL   = 4'h0;
    localparam bit [3:0] CONFIG = 4'h4;
    localparam bit [3:0] STATUS = 4'h8;
    localparam bit [3:0] DATA   = 4'hC;

    localparam bit [31:0] CTRL_START    = 32'h0000_0001;
    localparam bit [31:0] CTRL_RW_READ  = 32'h0000_0002;
    localparam bit [31:0] CTRL_ACK_IN   = 32'h0000_0004;
    localparam bit [31:0] CTRL_INTR_EN  = 32'h0000_0008;
    localparam bit [31:0] CTRL_DONE_CLR = 32'h0000_0010;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_ap = new("expected_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual iic_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "vif not found")
    endfunction

    task run_phase(uvm_phase phase);
        init_bus();
        wait (vif.resetn === 1'b1);
        repeat (3) @(vif.drv_cb);

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task automatic init_bus();
        vif.drv_cb.awaddr             <= '0;
        vif.drv_cb.awprot             <= '0;
        vif.drv_cb.awvalid            <= 1'b0;
        vif.drv_cb.wdata              <= '0;
        vif.drv_cb.wstrb              <= 4'h0;
        vif.drv_cb.wvalid             <= 1'b0;
        vif.drv_cb.bready             <= 1'b0;
        vif.drv_cb.araddr             <= '0;
        vif.drv_cb.arprot             <= '0;
        vif.drv_cb.arvalid            <= 1'b0;
        vif.drv_cb.rready             <= 1'b0;
        vif.drv_cb.reset_req          <= 1'b0;
        vif.drv_cb.target_own_addr    <= 7'h27;
        vif.drv_cb.target_tx_data     <= 8'h81;
        vif.drv_cb.target_ack_addr_en <= 1'b1;
        vif.drv_cb.target_ack_data_en <= 1'b1;
    endtask

    task automatic drive_item(ref iic_seq_item tr);
        drive_transfer(tr);
        `uvm_info(get_type_name(), tr.convert2string(), UVM_MEDIUM)
    endtask

    task automatic drive_transfer(ref iic_seq_item tr);
        bit [31:0] status;
        bit [31:0] data;
        iic_seq_item expected;

        setup_target(tr);
        write_config_and_data(tr);

        expected = iic_seq_item::type_id::create("expected");
        expected.copy(tr);
        expected_ap.write(expected);

        start_transfer(tr);
        if (tr.op == IIC_OP_BUSY_START) begin
            repeat (tr.clk_div * 3) @(vif.drv_cb);
            start_transfer(tr);
        end

        wait_done(status);
        axi_read(DATA, data);

        repeat (tr.clear_delay_cycles) @(vif.drv_cb);
        clear_done(tr);
    endtask

    task automatic setup_target(iic_seq_item tr);
        vif.drv_cb.target_own_addr    <= tr.target_own_addr;
        vif.drv_cb.target_tx_data     <= tr.target_tx_data;
        vif.drv_cb.target_ack_addr_en <= tr.ack_addr_en;
        vif.drv_cb.target_ack_data_en <= tr.ack_data_en;
        @(vif.drv_cb);
    endtask

    task automatic write_config_and_data(iic_seq_item tr);
        axi_write(CONFIG, {9'b0, tr.target_addr, tr.clk_div}, 4'b1111);
        axi_write(DATA, {24'h0, tr.tx_data}, 4'b0001);
    endtask

    task automatic start_transfer(iic_seq_item tr);
        bit [31:0] ctrl_value;
        ctrl_value = CTRL_START;
        if (tr.rw)      ctrl_value |= CTRL_RW_READ;
        if (tr.ack_in)  ctrl_value |= CTRL_ACK_IN;
        if (tr.intr_en) ctrl_value |= CTRL_INTR_EN;
        axi_write(CTRL, ctrl_value, 4'b0001);
    endtask

    task automatic clear_done(iic_seq_item tr);
        bit [31:0] ctrl_value;
        ctrl_value = CTRL_DONE_CLR;
        if (tr.rw)      ctrl_value |= CTRL_RW_READ;
        if (tr.ack_in)  ctrl_value |= CTRL_ACK_IN;
        if (tr.intr_en) ctrl_value |= CTRL_INTR_EN;
        axi_write(CTRL, ctrl_value, 4'b0001);
    endtask

    task automatic wait_done(output bit [31:0] status);
        int timeout;
        timeout = 0;
        do begin
            axi_read(STATUS, status);
            timeout++;
            if (timeout > 5000)
                `uvm_fatal(get_type_name(), $sformatf("IIC timeout status=0x%08h", status))
        end while ((status & 32'h0000_0002) == 0);
    endtask

    task automatic axi_write(input bit [3:0] addr, input bit [31:0] data, input bit [3:0] strb);
        @(vif.drv_cb);
        vif.drv_cb.awaddr  <= addr;
        vif.drv_cb.awvalid <= 1'b1;
        vif.drv_cb.wdata   <= data;
        vif.drv_cb.wstrb   <= strb;
        vif.drv_cb.wvalid  <= 1'b1;
        vif.drv_cb.bready  <= 1'b1;
        while (!(vif.drv_cb.awready && vif.drv_cb.wready)) @(vif.drv_cb);
        @(vif.drv_cb);
        vif.drv_cb.awvalid <= 1'b0;
        vif.drv_cb.wvalid  <= 1'b0;
        while (!vif.drv_cb.bvalid) @(vif.drv_cb);
        if (vif.drv_cb.bresp != 2'b00)
            `uvm_error(get_type_name(), $sformatf("AXI write response error addr=0x%0h bresp=%0b", addr, vif.drv_cb.bresp))
        @(vif.drv_cb);
        vif.drv_cb.bready <= 1'b0;
    endtask

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
        if (vif.drv_cb.rresp != 2'b00)
            `uvm_error(get_type_name(), $sformatf("AXI read response error addr=0x%0h rresp=%0b", addr, vif.drv_cb.rresp))
        @(vif.drv_cb);
        vif.drv_cb.rready <= 1'b0;
    endtask
endclass
