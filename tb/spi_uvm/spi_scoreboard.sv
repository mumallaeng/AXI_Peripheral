class spi_scoreboard extends uvm_scoreboard; //
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) imp;

    int m2s_pass, m2s_fail;   // master tx -> slave 수신
    int s2m_pass, s2m_fail;   // slave tx -> master RXDATA

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void write(spi_seq_item tr);
        // master → slave 경로
        if (tr.m_tx_data == tr.s_rx_byte) begin
            m2s_pass++;
            `uvm_info(get_type_name(), $sformatf("M->S PASS m_tx=%02h s_rx=%02h [%s]",
                      tr.m_tx_data, tr.s_rx_byte, mode_str(tr)), UVM_HIGH)
        end else begin
            m2s_fail++;
            `uvm_error(get_type_name(), $sformatf("M->S FAIL m_tx=%02h s_rx=%02h [%s]",
                      tr.m_tx_data, tr.s_rx_byte, mode_str(tr)))
        end
        // slave → master 경로
        if (tr.s_tx_data == tr.m_rx_data) begin
            s2m_pass++;
            `uvm_info(get_type_name(), $sformatf("S->M PASS s_tx=%02h m_rx=%02h [%s]",
                      tr.s_tx_data, tr.m_rx_data, mode_str(tr)), UVM_HIGH)
        end else begin
            s2m_fail++;
            `uvm_error(get_type_name(), $sformatf("S->M FAIL s_tx=%02h m_rx=%02h [%s]",
                      tr.s_tx_data, tr.m_rx_data, mode_str(tr)))
        end
    endfunction

    function string mode_str(spi_seq_item tr);
        return $sformatf("mode%0d cs=%0d div=%0d", {tr.cpol, tr.cpha}, tr.cs_sel, tr.clk_div);
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "==================================================", UVM_LOW)
        `uvm_info("SCB", "=============  SPI AXI Scoreboard  ================", UVM_LOW)
        `uvm_info("SCB", $sformatf(" Master->Slave : PASS=%0d FAIL=%0d", m2s_pass, m2s_fail), UVM_LOW)
        `uvm_info("SCB", $sformatf(" Slave->Master : PASS=%0d FAIL=%0d", s2m_pass, s2m_fail), UVM_LOW)
        `uvm_info("SCB", "==================================================", UVM_LOW)
        if (m2s_fail == 0 && s2m_fail == 0)
            `uvm_info("SCB", ">>> ALL PASS", UVM_LOW)
        else
            `uvm_warning("SCB", ">>> FAIL 존재 — mode1/mode3(CPHA=1)에서 DUT 타이밍 확인 필요")
    endfunction
endclass