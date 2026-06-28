typedef enum int {
    IIC_OP_WRITE,
    IIC_OP_READ,
    IIC_OP_ADDR_NACK,
    IIC_OP_DATA_NACK,
    IIC_OP_BUSY_START
} iic_op_e;

class iic_seq_item extends uvm_sequence_item;
    rand iic_op_e     op;
    rand bit          rw;
    rand bit          intr_en;
    rand bit          ack_in;
    rand bit [6:0]    target_addr;
    rand bit [6:0]    target_own_addr;
    rand bit [7:0]    tx_data;
    rand bit [7:0]    target_tx_data;
    rand bit [15:0]   clk_div;
    rand bit          ack_addr_en;
    rand bit          ack_data_en;
    rand int unsigned clear_delay_cycles;

    bit [7:0] observed_addr_byte;
    bit       observed_rw;
    bit       observed_addr_ack;
    bit       observed_data_ack;
    bit       observed_ctrl_ack;
    bit [7:0] observed_write_data;
    bit [7:0] observed_read_data;
    bit       observed_start;
    bit       observed_stop;
    bit       observed_busy_start;
    bit       intr_after_done;
    bit       intr_after_clear;

    constraint c_no_directed_overlap {
        target_addr != 7'h12;
        tx_data != 8'hA5;
        tx_data != 8'h5A;
        target_tx_data != 8'hC3;
    }

    constraint c_ranges {
        clk_div inside {16'd4, 16'd7, 16'd8, 16'd16, 16'd17, 16'd32, 16'd64};
        clear_delay_cycles inside {[0:8]};
    }

    `uvm_object_utils_begin(iic_seq_item)
        `uvm_field_enum(iic_op_e, op, UVM_ALL_ON)
        `uvm_field_int(rw, UVM_ALL_ON)
        `uvm_field_int(intr_en, UVM_ALL_ON)
        `uvm_field_int(ack_in, UVM_ALL_ON)
        `uvm_field_int(target_addr, UVM_ALL_ON)
        `uvm_field_int(target_own_addr, UVM_ALL_ON)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(target_tx_data, UVM_ALL_ON)
        `uvm_field_int(clk_div, UVM_ALL_ON)
        `uvm_field_int(ack_addr_en, UVM_ALL_ON)
        `uvm_field_int(ack_data_en, UVM_ALL_ON)
        `uvm_field_int(clear_delay_cycles, UVM_ALL_ON)
        `uvm_field_int(observed_addr_byte, UVM_ALL_ON)
        `uvm_field_int(observed_rw, UVM_ALL_ON)
        `uvm_field_int(observed_addr_ack, UVM_ALL_ON)
        `uvm_field_int(observed_data_ack, UVM_ALL_ON)
        `uvm_field_int(observed_ctrl_ack, UVM_ALL_ON)
        `uvm_field_int(observed_write_data, UVM_ALL_ON)
        `uvm_field_int(observed_read_data, UVM_ALL_ON)
        `uvm_field_int(observed_start, UVM_ALL_ON)
        `uvm_field_int(observed_stop, UVM_ALL_ON)
        `uvm_field_int(observed_busy_start, UVM_ALL_ON)
        `uvm_field_int(intr_after_done, UVM_ALL_ON)
        `uvm_field_int(intr_after_clear, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "iic_seq_item");
        super.new(name);
        op                 = IIC_OP_WRITE;
        rw                 = 1'b0;
        intr_en            = 1'b1;
        ack_in             = 1'b1;
        target_addr        = 7'h27;
        target_own_addr    = 7'h27;
        tx_data            = 8'h3C;
        target_tx_data     = 8'h81;
        clk_div            = 16'd8;
        ack_addr_en        = 1'b1;
        ack_data_en        = 1'b1;
        clear_delay_cycles = 0;
    endfunction

    function string convert2string();
        return $sformatf(
            "op=%s rw=%0b intr=%0b ack_in=%0b addr=0x%02h own=0x%02h tx=0x%02h tgt_tx=0x%02h div=%0d obs_addr=0x%02h obs_w=0x%02h obs_r=0x%02h",
            op.name(), rw, intr_en, ack_in, target_addr, target_own_addr,
            tx_data, target_tx_data, clk_div, observed_addr_byte,
            observed_write_data, observed_read_data);
    endfunction
endclass
