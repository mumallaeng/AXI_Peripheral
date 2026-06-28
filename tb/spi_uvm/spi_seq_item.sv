class spi_seq_item extends uvm_sequence_item; //

    // 입력 자극
    rand bit [7:0] m_tx_data;   // master가 보낼 바이트 (TXDATA)
    rand bit [7:0] s_tx_data;   // slave가 보낼 바이트 (slave 모델 셋업)
    rand bit       cpol;
    rand bit       cpha;
    rand bit [1:0] cs_sel;
    rand bit [7:0] clk_div;

    // 응답(모니터가 채움)
    bit [7:0] m_rx_data;        // master RXDATA (slave→master 결과)
    bit [7:0] s_rx_byte;        // slave가 받은 값 (master→slave 결과)

    constraint c_clk_div { clk_div inside {8'd0, 8'd1, 8'd2, 8'd4, 8'd8}; }
    constraint c_cs      { cs_sel  inside {2'd0, 2'd1, 2'd2, 2'd3}; }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(m_tx_data, UVM_ALL_ON)
        `uvm_field_int(s_tx_data, UVM_ALL_ON)
        `uvm_field_int(cpol,      UVM_ALL_ON)
        `uvm_field_int(cpha,      UVM_ALL_ON)
        `uvm_field_int(cs_sel,    UVM_ALL_ON)
        `uvm_field_int(clk_div,   UVM_ALL_ON)
        `uvm_field_int(m_rx_data, UVM_ALL_ON)
        `uvm_field_int(s_rx_byte, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "mode(cpol=%0b,cpha=%0b) cs=%0d div=%0d | m_tx=0x%02h s_rx=0x%02h | s_tx=0x%02h m_rx=0x%02h",
            cpol, cpha, cs_sel, clk_div, m_tx_data, s_rx_byte, s_tx_data, m_rx_data);
    endfunction
endclass