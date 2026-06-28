class iic_monitor extends uvm_monitor;
    `uvm_component_utils(iic_monitor)

    virtual iic_if vif;
    uvm_analysis_port #(iic_seq_item) ap;

    localparam bit [3:0] CTRL   = 4'h0;
    localparam bit [3:0] CONFIG = 4'h4;
    localparam bit [3:0] DATA   = 4'hC;

    bit        mirror_rw;
    bit        mirror_intr_en;
    bit        mirror_ack_in;
    bit [6:0]  mirror_target_addr;
    bit [15:0] mirror_clk_div;
    bit [7:0]  mirror_tx_data;
    bit [6:0]  mirror_own_addr;
    bit [7:0]  mirror_target_tx_data;
    bit        mirror_ack_addr_en;
    bit        mirror_ack_data_en;

    bit transfer_active;
    bit busy_start_seen;
    event done_clear_seen;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual iic_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "vif not found")
    endfunction

    task run_phase(uvm_phase phase);
        init_mirror();
        fork
            track_axi_writes();
            collect_iic_bus();
        join
    endtask

    task automatic init_mirror();
        mirror_rw             = 1'b0;
        mirror_intr_en        = 1'b0;
        mirror_ack_in         = 1'b1;
        mirror_target_addr    = 7'h27;
        mirror_clk_div        = 16'd8;
        mirror_tx_data        = 8'h00;
        mirror_own_addr       = 7'h27;
        mirror_target_tx_data = 8'h81;
        mirror_ack_addr_en    = 1'b1;
        mirror_ack_data_en    = 1'b1;
        transfer_active       = 1'b0;
        busy_start_seen       = 1'b0;
    endtask

    task automatic track_axi_writes();
        forever begin
            @(posedge vif.clk);

            mirror_own_addr       = vif.target_own_addr;
            mirror_target_tx_data = vif.target_tx_data;
            mirror_ack_addr_en    = vif.target_ack_addr_en;
            mirror_ack_data_en    = vif.target_ack_data_en;

            if (!vif.resetn) begin
                init_mirror();
            end else if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin
                case (vif.awaddr)
                    CTRL: begin
                        mirror_rw      = vif.wdata[1];
                        mirror_ack_in  = vif.wdata[2];
                        mirror_intr_en = vif.wdata[3];

                        if (vif.wdata[0] && transfer_active) begin
                            busy_start_seen = 1'b1;
                        end

                        if (vif.wdata[4]) begin
                            -> done_clear_seen;
                        end
                    end

                    CONFIG: begin
                        mirror_clk_div     = vif.wdata[15:0];
                        mirror_target_addr = vif.wdata[22:16];
                    end

                    DATA: begin
                        mirror_tx_data = vif.wdata[7:0];
                    end

                    default: begin
                    end
                endcase
            end
        end
    endtask

    task automatic collect_iic_bus();
        forever begin
            iic_seq_item tr;
            bit [7:0] addr_byte;
            bit [7:0] data_byte;
            bit       ack_seen;

            wait (vif.resetn === 1'b1);
            wait_start_condition();

            tr = iic_seq_item::type_id::create("observed");
            transfer_active = 1'b1;
            busy_start_seen = 1'b0;

            tr.intr_en            = mirror_intr_en;
            tr.ack_in             = mirror_ack_in;
            tr.target_own_addr    = mirror_own_addr;
            tr.target_tx_data     = mirror_target_tx_data;
            tr.clk_div            = mirror_clk_div;
            tr.tx_data            = mirror_tx_data;
            tr.ack_addr_en        = mirror_ack_addr_en;
            tr.ack_data_en        = mirror_ack_data_en;
            tr.observed_start     = 1'b1;

            read_iic_byte(addr_byte);
            tr.observed_addr_byte = addr_byte;
            tr.target_addr        = addr_byte[7:1];
            tr.rw                 = addr_byte[0];
            tr.observed_rw        = addr_byte[0];

            read_iic_ack(ack_seen);
            tr.observed_addr_ack = ack_seen;

            if (addr_byte[0]) begin
                read_iic_byte(data_byte);
                tr.observed_read_data = data_byte;
                read_iic_ack(ack_seen);
                tr.observed_ctrl_ack = ack_seen;
            end else begin
                read_iic_byte(data_byte);
                tr.observed_write_data = data_byte;
                read_iic_ack(ack_seen);
                tr.observed_data_ack = ack_seen;
            end

            wait_stop_condition();
            tr.observed_stop = 1'b1;

            repeat (2) @(posedge vif.clk);
            tr.intr_after_done = vif.intr;

            wait_done_clear();
            @(posedge vif.clk);
            tr.intr_after_clear = vif.intr;

            if (busy_start_seen) begin
                tr.op = IIC_OP_BUSY_START;
            end else if (!tr.observed_addr_ack) begin
                tr.op = IIC_OP_ADDR_NACK;
            end else if (!tr.rw && !tr.observed_data_ack) begin
                tr.op = IIC_OP_DATA_NACK;
            end else if (tr.rw) begin
                tr.op = IIC_OP_READ;
            end else begin
                tr.op = IIC_OP_WRITE;
            end

            tr.observed_busy_start = busy_start_seen;
            transfer_active = 1'b0;
            ap.write(tr);
        end
    endtask

    task automatic wait_start_condition();
        bit prev_sda;
        prev_sda = 1'b1;
        forever begin
            @(posedge vif.clk);
            if (vif.resetn && vif.scl === 1'b1 && prev_sda === 1'b1 && vif.sda === 1'b0) begin
                return;
            end
            prev_sda = vif.sda;
        end
    endtask

    task automatic wait_stop_condition();
        bit prev_sda;
        prev_sda = vif.sda;
        forever begin
            @(posedge vif.clk);
            if (vif.resetn && vif.scl === 1'b1 && prev_sda === 1'b0 && vif.sda === 1'b1) begin
                return;
            end
            prev_sda = vif.sda;
        end
    endtask

    task automatic read_iic_byte(output bit [7:0] data);
        bit sampled_sda;
        data = '0;
        for (int i = 0; i < 8; i++) begin
            wait_scl_rise(sampled_sda);
            data = {data[6:0], sampled_sda};
        end
    endtask

    task automatic read_iic_ack(output bit ack_seen);
        bit sampled_sda;
        wait_scl_rise(sampled_sda);
        ack_seen = ~sampled_sda;
    endtask

    task automatic wait_scl_rise(output bit sampled_sda);
        bit prev_scl;
        prev_scl = vif.scl;
        forever begin
            @(posedge vif.clk);
            if (vif.resetn && prev_scl === 1'b0 && vif.scl === 1'b1) begin
                sampled_sda = vif.sda;
                return;
            end
            prev_scl = vif.scl;
        end
    endtask

    task automatic wait_done_clear();
        fork
            begin
                @done_clear_seen;
            end
            begin
                repeat (6000) @(posedge vif.clk);
                `uvm_error(get_type_name(), "timeout waiting done clear write")
            end
        join_any
        disable fork;
    endtask
endclass
