class iic_base_seq extends uvm_sequence #(iic_seq_item);
    `uvm_object_utils(iic_base_seq)

    function new(string name = "iic_base_seq");
        super.new(name);
    endfunction

    task send_item(
        iic_op_e op,
        bit rw,
        bit [6:0] addr,
        bit [6:0] own,
        bit [7:0] tx,
        bit [7:0] target_tx,
        bit [15:0] div,
        bit intr_en = 1'b1,
        bit ack_in = 1'b1,
        bit ack_addr_en = 1'b1,
        bit ack_data_en = 1'b1,
        int unsigned clear_delay = 0
    );
        iic_seq_item item;
        item = iic_seq_item::type_id::create("item");
        start_item(item);
        item.op                 = op;
        item.rw                 = rw;
        item.target_addr        = addr;
        item.target_own_addr    = own;
        item.tx_data            = tx;
        item.target_tx_data     = target_tx;
        item.clk_div            = div;
        item.intr_en            = intr_en;
        item.ack_in             = ack_in;
        item.ack_addr_en        = ack_addr_en;
        item.ack_data_en        = ack_data_en;
        item.clear_delay_cycles = clear_delay;
        finish_item(item);
    endtask
endclass

class iic_axi_seq extends iic_base_seq;
    `uvm_object_utils(iic_axi_seq)

    function new(string name = "iic_axi_seq");
        super.new(name);
    endfunction

    task body();
        send_item(IIC_OP_WRITE, 0, 7'h18, 7'h18, 8'h00, 8'h22, 16'd4,  1, 1, 1, 1, 0);
        send_item(IIC_OP_WRITE, 0, 7'h5A, 7'h5A, 8'hFF, 8'h0F, 16'd64, 0, 1, 1, 1, 3);
    endtask
endclass

class iic_peripheral_seq extends iic_base_seq;
    `uvm_object_utils(iic_peripheral_seq)

    function new(string name = "iic_peripheral_seq");
        super.new(name);
    endfunction

    task body();
        send_item(IIC_OP_WRITE,      0, 7'h27, 7'h27, 8'h3C, 8'h81, 16'd8,  1, 1, 1, 1, 0);
        send_item(IIC_OP_READ,       1, 7'h2A, 7'h2A, 8'h11, 8'h81, 16'd16, 1, 1, 1, 1, 2);
        send_item(IIC_OP_WRITE,      0, 7'h61, 7'h61, 8'hF0, 8'h44, 16'd32, 0, 1, 1, 1, 4);
        send_item(IIC_OP_BUSY_START, 0, 7'h35, 7'h35, 8'h6D, 8'h19, 16'd16, 1, 1, 1, 1, 1);
    endtask
endclass

class iic_protocol_seq extends iic_base_seq;
    `uvm_object_utils(iic_protocol_seq)

    function new(string name = "iic_protocol_seq");
        super.new(name);
    endfunction

    task body();
        send_item(IIC_OP_ADDR_NACK, 0, 7'h33, 7'h34, 8'h24, 8'h66, 16'd8,  1, 1, 1, 1, 0);
        send_item(IIC_OP_ADDR_NACK, 1, 7'h40, 7'h41, 8'h88, 8'h7E, 16'd16, 1, 1, 1, 1, 0);
        send_item(IIC_OP_DATA_NACK, 0, 7'h29, 7'h29, 8'hE1, 8'h21, 16'd7,  1, 1, 1, 0, 3);
        send_item(IIC_OP_READ,      1, 7'h7A, 7'h7A, 8'h09, 8'h00, 16'd4,  1, 0, 1, 1, 1);
        send_item(IIC_OP_READ,      1, 7'h01, 7'h01, 8'h10, 8'hFF, 16'd64, 1, 1, 1, 1, 8);
    endtask
endclass

class iic_random_seq extends uvm_sequence #(iic_seq_item);
    `uvm_object_utils(iic_random_seq)

    rand int unsigned num;
    constraint c_num { num inside {[150:600]}; }

    function new(string name = "iic_random_seq");
        super.new(name);
    endfunction

    task body();
        iic_seq_item item;
        int unsigned plus_num;
        if ($value$plusargs("NUM=%d", plus_num))
            num = plus_num;

        repeat (num) begin
            item = iic_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                op inside {IIC_OP_WRITE, IIC_OP_READ, IIC_OP_ADDR_NACK, IIC_OP_DATA_NACK};
                if (op == IIC_OP_WRITE) {
                    rw == 0;
                    target_own_addr == target_addr;
                    ack_addr_en == 1;
                    ack_data_en == 1;
                }
                if (op == IIC_OP_READ) {
                    rw == 1;
                    target_own_addr == target_addr;
                    ack_addr_en == 1;
                    ack_data_en == 1;
                }
                if (op == IIC_OP_ADDR_NACK) {
                    target_own_addr != target_addr;
                    ack_addr_en == 1;
                }
                if (op == IIC_OP_DATA_NACK) {
                    rw == 0;
                    target_own_addr == target_addr;
                    ack_addr_en == 1;
                    ack_data_en == 0;
                }
            })
                `uvm_error("SEQ", "randomize failed")
            finish_item(item);
        end
    endtask
endclass
