// ── 모든 모드 sweep: 4모드 x 패턴 (방향성 검증) ─────────────
class spi_mode_seq extends uvm_sequence #(spi_seq_item); //
    `uvm_object_utils(spi_mode_seq)
    function new(string name = "spi_mode_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] patterns[] = '{8'h00, 8'hFF, 8'hAA, 8'h55, 8'h80, 8'h01, 8'h3C};
        for (int p = 0; p < 2; p++) begin       // cpol
            for (int h = 0; h < 2; h++) begin    // cpha
                foreach (patterns[i]) begin
                    spi_seq_item item = spi_seq_item::type_id::create("item");
                    start_item(item);
                    item.cpol      = p[0];
                    item.cpha      = h[0];
                    item.cs_sel    = i % 4;
                    item.clk_div   = 8'd1;
                    item.m_tx_data = patterns[i];
                    item.s_tx_data = ~patterns[i];
                    finish_item(item);
                end
            end
        end
    endtask
endclass

// ── 완전 랜덤 ──────────────────────────────────────────────
class spi_random_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_random_seq)
    rand int num;
    constraint c_num { num inside {[300:600]}; }
    function new(string name = "spi_random_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("random %0d 반복", num), UVM_LOW)
        repeat (num) begin
            spi_seq_item item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("SEQ", "randomize 실패")
            finish_item(item);
        end
    endtask
endclass

// ── full 데이터 sweep (mode0 고정, 0~255) ───────────────────
class spi_full_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_full_seq)
    function new(string name = "spi_full_seq");
        super.new(name);
    endfunction

    task body();
        for (int i = 0; i < 256; i++) begin
            spi_seq_item item = spi_seq_item::type_id::create("item");
            start_item(item);
            item.cpol = 0; item.cpha = 0; item.cs_sel = i % 4; item.clk_div = 8'd1;
            item.m_tx_data = i;
            item.s_tx_data = ~i[7:0];
            finish_item(item);
        end
    endtask
endclass