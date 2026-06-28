class iic_coverage extends uvm_subscriber #(iic_seq_item);
    `uvm_component_utils(iic_coverage)

    iic_seq_item tr;

    covergroup iic_cg;
        option.per_instance = 1;

        cp_op: coverpoint tr.op;
        cp_rw: coverpoint tr.rw;
        cp_intr: coverpoint tr.intr_en;
        cp_ack_in: coverpoint tr.ack_in;
        cp_addr_match: coverpoint (tr.target_addr == tr.target_own_addr);
        cp_addr: coverpoint tr.target_addr {
            bins low  = {[7'h00:7'h1F]};
            bins mid  = {[7'h20:7'h5F]};
            bins high = {[7'h60:7'h7F]};
        }
        cp_tx: coverpoint tr.tx_data {
            bins zero = {8'h00};
            bins lo   = {[8'h01:8'h54]};
            bins mid  = {[8'h55:8'hAA]};
            bins hi   = {[8'hAB:8'hFE]};
            bins max  = {8'hFF};
        }
        cp_rx: coverpoint tr.target_tx_data {
            bins zero = {8'h00};
            bins lo   = {[8'h01:8'h54]};
            bins mid  = {[8'h55:8'hAA]};
            bins hi   = {[8'hAB:8'hFE]};
            bins max  = {8'hFF};
        }
        cp_div: coverpoint tr.clk_div {
            bins div_small = {16'd4, 16'd7, 16'd8};
            bins div_mid   = {16'd16, 16'd17, 16'd32};
            bins div_large = {16'd64};
        }
        cp_ack_addr: coverpoint tr.ack_addr_en;
        cp_ack_data: coverpoint tr.ack_data_en;
        cp_clear_delay: coverpoint tr.clear_delay_cycles {
            bins immediate = {0};
            bins short     = {[1:3]};
            bins delayed   = {[4:8]};
        }
        cp_start: coverpoint tr.observed_start;
        cp_stop: coverpoint tr.observed_stop;
        cp_addr_ack: coverpoint tr.observed_addr_ack;
        cp_data_ack: coverpoint tr.observed_data_ack;

        cx_op_rw: cross cp_op, cp_rw;
        cx_addr_ack: cross cp_addr_match, cp_ack_addr;
        cx_intr_start: cross cp_intr, cp_start;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        iic_cg = new();
    endfunction

    function void write(iic_seq_item t);
        tr = t;
        iic_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", "==================================================", UVM_LOW)
        `uvm_info("COV", $sformatf("IIC functional coverage: %6.2f %%", iic_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("op coverage          : %6.2f %%", iic_cg.cp_op.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("addr coverage        : %6.2f %%", iic_cg.cp_addr.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("data coverage        : %6.2f %%", iic_cg.cp_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("clk_div coverage     : %6.2f %%", iic_cg.cp_div.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", "==================================================", UVM_LOW)
    endfunction
endclass
