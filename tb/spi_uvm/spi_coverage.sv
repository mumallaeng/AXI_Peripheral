class spi_coverage extends uvm_subscriber #(spi_seq_item);  //
    `uvm_component_utils(spi_coverage)

    spi_seq_item tr;

    covergroup spi_cg;
        option.per_instance = 1;

        cp_mtx: coverpoint tr.m_tx_data {
            bins min = {8'h00};
            bins lo = {[8'h01 : 8'h54]};
            bins mid = {[8'h55 : 8'hAA]};
            bins hi = {[8'hAB : 8'hFE]};
            bins max = {8'hFF};
        }
        cp_stx: coverpoint tr.s_tx_data {
            bins min = {8'h00};
            bins lo = {[8'h01 : 8'h54]};
            bins mid = {[8'h55 : 8'hAA]};
            bins hi = {[8'hAB : 8'hFE]};
            bins max = {8'hFF};
        }
        cp_cpol: coverpoint tr.cpol;
        cp_cpha: coverpoint tr.cpha;
        cp_mode: cross cp_cpol, cp_cpha;  // 4모드 전부
        cp_cs: coverpoint tr.cs_sel {bins cs[] = {0, 1, 2, 3};}
        cp_div: coverpoint tr.clk_div {
            bins d0 = {8'd0};
            bins d1 = {8'd1};
            bins d2 = {8'd2};
            bins d4 = {8'd4};
            bins d8 = {8'd8};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    function void write(spi_seq_item t);
        tr = t;
        spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", "==================================================",
                  UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            " 전체 커버리지   : %6.2f %%", spi_cg.get_inst_coverage()),
            UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            " cp_mode(4모드)  : %6.2f %%", spi_cg.cp_mode.get_inst_coverage()
            ), UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            " cp_cs           : %6.2f %%", spi_cg.cp_cs.get_inst_coverage()),
            UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            " cp_div          : %6.2f %%", spi_cg.cp_div.get_inst_coverage()),
            UVM_LOW)
        `uvm_info("COV", "==================================================",
                  UVM_LOW)
        if (spi_cg.get_inst_coverage() < 100.0)
            `uvm_warning(
                "COV",
                "커버리지 100% 미달 — 시나리오 추가 권장")
    endfunction
endclass
