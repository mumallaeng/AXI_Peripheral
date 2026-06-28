`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_observed)

class iic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(iic_scoreboard)

    uvm_analysis_imp_expected #(iic_seq_item, iic_scoreboard) expected_imp;
    uvm_analysis_imp_observed #(iic_seq_item, iic_scoreboard) observed_imp;

    iic_seq_item expected_q[$];
    int pass_count;
    int fail_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_imp = new("expected_imp", this);
        observed_imp = new("observed_imp", this);
    endfunction

    function void write_expected(iic_seq_item tr);
        iic_seq_item expected;
        expected = iic_seq_item::type_id::create("expected");
        expected.copy(tr);
        expected_q.push_back(expected);
    endfunction

    function void write_observed(iic_seq_item observed);
        iic_seq_item expected;
        bit ok;

        if (expected_q.size() == 0) begin
            fail_count++;
            `uvm_error("SCB", $sformatf("Observed item without expected item: %s", observed.convert2string()))
            return;
        end

        expected = expected_q.pop_front();
        ok = 1'b1;

        check_enum("OP", observed.op, expected.op, ok);
        check_bit("RW", observed.rw, expected.rw, ok);
        check_eq7("ADDR", observed.target_addr, expected.target_addr, ok);
        check_eq8("ADDR_BYTE", observed.observed_addr_byte, {expected.target_addr, expected.rw}, ok);
        check_bit("START", observed.observed_start, 1'b1, ok);
        check_bit("STOP", observed.observed_stop, 1'b1, ok);
        check_bit("INTR_AFTER_DONE", observed.intr_after_done, expected.intr_en, ok);
        check_bit("INTR_AFTER_CLEAR", observed.intr_after_clear, 1'b0, ok);

        case (expected.op)
            IIC_OP_WRITE: begin
                check_bit("ADDR_ACK", observed.observed_addr_ack, 1'b1, ok);
                check_bit("DATA_ACK", observed.observed_data_ack, 1'b1, ok);
                check_eq8("WRITE_DATA", observed.observed_write_data, expected.tx_data, ok);
            end

            IIC_OP_READ: begin
                check_bit("ADDR_ACK", observed.observed_addr_ack, 1'b1, ok);
                check_eq8("READ_DATA", observed.observed_read_data, expected.target_tx_data, ok);
            end

            IIC_OP_ADDR_NACK: begin
                check_bit("ADDR_ACK", observed.observed_addr_ack, 1'b0, ok);
            end

            IIC_OP_DATA_NACK: begin
                check_bit("ADDR_ACK", observed.observed_addr_ack, 1'b1, ok);
                check_bit("DATA_ACK", observed.observed_data_ack, 1'b0, ok);
                check_eq8("WRITE_DATA", observed.observed_write_data, expected.tx_data, ok);
            end

            IIC_OP_BUSY_START: begin
                check_bit("BUSY_START", observed.observed_busy_start, 1'b1, ok);
                check_bit("ADDR_ACK", observed.observed_addr_ack, 1'b1, ok);
                check_eq8("WRITE_DATA", observed.observed_write_data, expected.tx_data, ok);
            end

            default: begin
                ok = 1'b0;
                `uvm_error("SCB", "Unsupported expected op")
            end
        endcase

        if (ok) begin
            pass_count++;
            `uvm_info("SCB_PASS", observed.convert2string(), UVM_MEDIUM)
        end else begin
            fail_count++;
            `uvm_error("SCB_FAIL", $sformatf("expected={%s} observed={%s}", expected.convert2string(), observed.convert2string()))
        end
    endfunction

    function void check_enum(string tag, iic_op_e actual, iic_op_e expected, ref bit ok);
        if (actual != expected) begin
            ok = 1'b0;
            `uvm_error("SCB", $sformatf("%s actual=%s expected=%s", tag, actual.name(), expected.name()))
        end
    endfunction

    function void check_eq7(string tag, bit [6:0] actual, bit [6:0] expected, ref bit ok);
        if (actual !== expected) begin
            ok = 1'b0;
            `uvm_error("SCB", $sformatf("%s actual=0x%02h expected=0x%02h", tag, actual, expected))
        end
    endfunction

    function void check_eq8(string tag, bit [7:0] actual, bit [7:0] expected, ref bit ok);
        if (actual !== expected) begin
            ok = 1'b0;
            `uvm_error("SCB", $sformatf("%s actual=0x%02h expected=0x%02h", tag, actual, expected))
        end
    endfunction

    function void check_bit(string tag, bit actual, bit expected, ref bit ok);
        if (actual !== expected) begin
            ok = 1'b0;
            `uvm_error("SCB", $sformatf("%s actual=%0b expected=%0b", tag, actual, expected))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        if (expected_q.size() != 0) begin
            fail_count += expected_q.size();
            `uvm_error("SCB", $sformatf("Expected queue not empty: %0d", expected_q.size()))
        end

        `uvm_info("SCB", "==================================================", UVM_LOW)
        `uvm_info("SCB", $sformatf("IIC scoreboard PASS=%0d FAIL=%0d", pass_count, fail_count), UVM_LOW)
        `uvm_info("SCB", "==================================================", UVM_LOW)
        if (fail_count == 0)
            `uvm_info("SCB", ">>> ALL PASS", UVM_LOW)
        else
            `uvm_error("SCB", ">>> FAIL exists")
    endfunction
endclass
