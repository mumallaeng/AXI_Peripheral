`timescale 1ns / 1ps

module tb_iic;

    localparam logic [3:0] IIC_CTRL_ADDR   = 4'h0;
    localparam logic [3:0] IIC_CONFIG_ADDR = 4'h4;
    localparam logic [3:0] IIC_STATUS_ADDR = 4'h8;
    localparam logic [3:0] IIC_DATA_ADDR   = 4'hC;

    localparam logic [6:0] TARGET_ADDR = 7'h12;
    localparam logic [7:0] WRITE_DATA0 = 8'hA5;
    localparam logic [7:0] WRITE_DATA1 = 8'h5A;
    localparam logic [7:0] READ_DATA0  = 8'hC3;

    localparam logic [31:0] CTRL_START    = 32'h0000_0001;
    localparam logic [31:0] CTRL_RW_READ  = 32'h0000_0002;
    localparam logic [31:0] CTRL_ACK_IN   = 32'h0000_0004;
    localparam logic [31:0] CTRL_INTR_EN  = 32'h0000_0008;
    localparam logic [31:0] CTRL_DONE_CLR = 32'h0000_0010;

    logic        clk;
    logic        reset_n;

    wire         scl;
    wire         sda;
    logic        target_sda_drive_low;
    logic [ 7:0] target_rx_data;
    logic        target_rx_valid;
    logic [ 7:0] target_tx_data;

    logic        intr;
    logic        s00_axi_aclk;
    logic        s00_axi_aresetn;
    logic [ 3:0] s00_axi_awaddr;
    logic [ 2:0] s00_axi_awprot;
    logic        s00_axi_awvalid;
    logic        s00_axi_awready;
    logic [31:0] s00_axi_wdata;
    logic [ 3:0] s00_axi_wstrb;
    logic        s00_axi_wvalid;
    logic        s00_axi_wready;
    logic [ 1:0] s00_axi_bresp;
    logic        s00_axi_bvalid;
    logic        s00_axi_bready;
    logic [ 3:0] s00_axi_araddr;
    logic [ 2:0] s00_axi_arprot;
    logic        s00_axi_arvalid;
    logic        s00_axi_arready;
    logic [31:0] s00_axi_rdata;
    logic [ 1:0] s00_axi_rresp;
    logic        s00_axi_rvalid;
    logic        s00_axi_rready;

    pullup (scl);
    pullup (sda);

    assign s00_axi_aclk    = clk;
    assign s00_axi_aresetn = reset_n;
    assign sda             = target_sda_drive_low ? 1'b0 : 1'bz;

    iic_v1_0 dut (
        .scl              (scl),
        .sda              (sda),
        .intr             (intr),
        .s00_axi_aclk     (s00_axi_aclk),
        .s00_axi_aresetn  (s00_axi_aresetn),
        .s00_axi_awaddr   (s00_axi_awaddr),
        .s00_axi_awprot   (s00_axi_awprot),
        .s00_axi_awvalid  (s00_axi_awvalid),
        .s00_axi_awready  (s00_axi_awready),
        .s00_axi_wdata    (s00_axi_wdata),
        .s00_axi_wstrb    (s00_axi_wstrb),
        .s00_axi_wvalid   (s00_axi_wvalid),
        .s00_axi_wready   (s00_axi_wready),
        .s00_axi_bresp    (s00_axi_bresp),
        .s00_axi_bvalid   (s00_axi_bvalid),
        .s00_axi_bready   (s00_axi_bready),
        .s00_axi_araddr   (s00_axi_araddr),
        .s00_axi_arprot   (s00_axi_arprot),
        .s00_axi_arvalid  (s00_axi_arvalid),
        .s00_axi_arready  (s00_axi_arready),
        .s00_axi_rdata    (s00_axi_rdata),
        .s00_axi_rresp    (s00_axi_rresp),
        .s00_axi_rvalid   (s00_axi_rvalid),
        .s00_axi_rready   (s00_axi_rready)
    );

    tb_iic_target_model #(
        .OWN_ADDR(TARGET_ADDR)
    ) target_model (
        .clk          (clk),
        .reset_n      (reset_n),
        .scl          (scl),
        .sda          (sda),
        .tx_data      (target_tx_data),
        .sda_drive_low(target_sda_drive_low),
        .rx_data      (target_rx_data),
        .rx_valid     (target_rx_valid)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic AXI_WriteData(input logic [3:0] addr, input logic [31:0] data);
        begin
            s00_axi_awaddr  <= addr;
            s00_axi_awvalid <= 1'b1;
            s00_axi_wdata   <= data;
            s00_axi_wvalid  <= 1'b1;
            s00_axi_bready  <= 1'b1;
            s00_axi_wstrb   <= 4'b1111;

            @(posedge clk);
            wait (s00_axi_awready && s00_axi_wready);
            @(posedge clk);
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid  <= 1'b0;

            wait (s00_axi_bvalid);
            if (s00_axi_bresp != 2'b00) begin
                $fatal(1, "AXI write response error addr=%h bresp=%b", addr, s00_axi_bresp);
            end
            @(posedge clk);
            s00_axi_bready <= 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic AXI_ReadData(input logic [3:0] addr, output logic [31:0] data);
        begin
            s00_axi_araddr  <= addr;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            @(posedge clk);
            wait (s00_axi_arready);
            @(posedge clk);
            s00_axi_arvalid <= 1'b0;

            wait (s00_axi_rvalid);
            data = s00_axi_rdata;
            if (s00_axi_rresp != 2'b00) begin
                $fatal(1, "AXI read response error addr=%h rresp=%b", addr, s00_axi_rresp);
            end
            @(posedge clk);
            s00_axi_rready <= 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic IIC_WaitDone(output logic [31:0] status);
        int timeout;
        begin
            timeout = 0;
            do begin
                AXI_ReadData(IIC_STATUS_ADDR, status);
                timeout++;
                if (timeout > 2000) begin
                    $fatal(1, "IIC timeout status=%h", status);
                end
            end while ((status & 32'h0000_0002) == 0);
        end
    endtask

    task automatic IIC_ClearDone();
        begin
            AXI_WriteData(IIC_CTRL_ADDR, CTRL_DONE_CLR | CTRL_INTR_EN | CTRL_ACK_IN);
        end
    endtask

    task automatic IIC_WriteByte(input logic [7:0] data);
        logic [31:0] status;
        begin
            AXI_WriteData(IIC_DATA_ADDR, data);
            AXI_WriteData(IIC_CTRL_ADDR, CTRL_START | CTRL_INTR_EN | CTRL_ACK_IN);
            IIC_WaitDone(status);

            if (!status[2]) begin
                $fatal(1, "IIC write ACK was not seen: status=%h", status);
            end
            if (!intr) begin
                $fatal(1, "IIC interrupt was not asserted after write");
            end
            if (target_rx_data !== data) begin
                $fatal(1, "IIC target RX mismatch actual=%h expected=%h", target_rx_data, data);
            end
            IIC_ClearDone();
            @(posedge clk);
            if (intr) begin
                $fatal(1, "IIC interrupt did not clear");
            end
        end
    endtask

    task automatic IIC_ReadByte(input logic [7:0] expected);
        logic [31:0] status;
        logic [31:0] data_reg;
        begin
            target_tx_data = expected;
            AXI_WriteData(IIC_CTRL_ADDR, CTRL_START | CTRL_RW_READ | CTRL_INTR_EN | CTRL_ACK_IN);
            IIC_WaitDone(status);
            AXI_ReadData(IIC_DATA_ADDR, data_reg);

            if (!status[2]) begin
                $fatal(1, "IIC read address ACK was not seen: status=%h", status);
            end
            if (status[15:8] !== expected) begin
                $fatal(1, "IIC status RX mismatch actual=%h expected=%h", status[15:8], expected);
            end
            if (data_reg[15:8] !== expected) begin
                $fatal(1, "IIC data register RX mismatch actual=%h expected=%h", data_reg[15:8], expected);
            end
            IIC_ClearDone();
        end
    endtask

    initial begin
        reset_n            = 1'b0;
        target_tx_data     = READ_DATA0;
        s00_axi_awaddr     = '0;
        s00_axi_awprot     = '0;
        s00_axi_awvalid    = 1'b0;
        s00_axi_wdata      = '0;
        s00_axi_wstrb      = '0;
        s00_axi_wvalid     = 1'b0;
        s00_axi_bready     = 1'b0;
        s00_axi_araddr     = '0;
        s00_axi_arprot     = '0;
        s00_axi_arvalid    = 1'b0;
        s00_axi_rready     = 1'b0;

        repeat (5) @(posedge clk);
        reset_n = 1'b1;
        repeat (5) @(posedge clk);

        AXI_WriteData(IIC_CONFIG_ADDR, {9'b0, TARGET_ADDR, 16'd32});

        IIC_WriteByte(WRITE_DATA0);
        IIC_WriteByte(WRITE_DATA1);
        IIC_ReadByte(READ_DATA0);

        $display("tb_iic PASS");
        #100;
        $finish;
    end

endmodule

module tb_iic_target_model #(
    parameter logic [6:0] OWN_ADDR = 7'h12
) (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       scl,
    input  logic       sda,
    input  logic [7:0] tx_data,
    output logic       sda_drive_low,
    output logic [7:0] rx_data,
    output logic       rx_valid
);

    typedef enum logic [2:0] {
        TGT_IDLE,
        TGT_RX_ADDR,
        TGT_ADDR_ACK,
        TGT_RX_DATA,
        TGT_DATA_ACK,
        TGT_TX_DATA,
        TGT_WAIT_ACK,
        TGT_IGNORE
    } state_t;

    state_t     state;
    logic       scl_meta;
    logic       scl_sync;
    logic       scl_prev;
    logic       sda_meta;
    logic       sda_sync;
    logic       sda_prev;
    logic [7:0] addr_shift_reg;
    logic [7:0] data_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;
    logic       rw;
    logic       ack_active;

    wire start_detect = (scl_sync == 1'b1) && (sda_prev == 1'b1) && (sda_sync == 1'b0);
    wire stop_detect  = (scl_sync == 1'b1) && (sda_prev == 1'b0) && (sda_sync == 1'b1);
    wire scl_rise     = (scl_prev == 1'b0) && (scl_sync == 1'b1);
    wire scl_fall     = (scl_prev == 1'b1) && (scl_sync == 1'b0);

    always_ff @(posedge clk or negedge reset_n) begin
        logic [7:0] addr_byte;
        logic [7:0] data_byte;

        if (!reset_n) begin
            state          <= TGT_IDLE;
            scl_meta       <= 1'b1;
            scl_sync       <= 1'b1;
            scl_prev       <= 1'b1;
            sda_meta       <= 1'b1;
            sda_sync       <= 1'b1;
            sda_prev       <= 1'b1;
            addr_shift_reg <= '0;
            data_shift_reg <= '0;
            tx_shift_reg   <= '0;
            bit_cnt        <= '0;
            rw             <= 1'b0;
            ack_active     <= 1'b0;
            sda_drive_low  <= 1'b0;
            rx_data        <= '0;
            rx_valid       <= 1'b0;
        end else begin
            scl_meta <= scl;
            scl_sync <= scl_meta;
            scl_prev <= scl_sync;
            sda_meta <= sda;
            sda_sync <= sda_meta;
            sda_prev <= sda_sync;
            rx_valid <= 1'b0;

            if (start_detect) begin
                state          <= TGT_RX_ADDR;
                addr_shift_reg <= '0;
                data_shift_reg <= '0;
                bit_cnt        <= '0;
                rw             <= 1'b0;
                ack_active     <= 1'b0;
                sda_drive_low  <= 1'b0;
            end else if (stop_detect) begin
                state         <= TGT_IDLE;
                bit_cnt       <= '0;
                ack_active    <= 1'b0;
                sda_drive_low <= 1'b0;
            end else begin
                case (state)
                    TGT_IDLE: begin
                        sda_drive_low <= 1'b0;
                    end

                    TGT_RX_ADDR: begin
                        if (scl_rise) begin
                            addr_byte      = {addr_shift_reg[6:0], sda_sync};
                            addr_shift_reg <= addr_byte;

                            if (bit_cnt == 3'd7) begin
                                rw      <= addr_byte[0];
                                bit_cnt <= '0;
                                if (addr_byte[7:1] == OWN_ADDR) begin
                                    state <= TGT_ADDR_ACK;
                                end else begin
                                    state <= TGT_IGNORE;
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    TGT_ADDR_ACK: begin
                        if (scl_fall && !ack_active) begin
                            sda_drive_low <= 1'b1;
                            ack_active    <= 1'b1;
                        end else if (scl_fall && ack_active) begin
                            sda_drive_low <= 1'b0;
                            ack_active    <= 1'b0;
                            bit_cnt       <= '0;

                            if (rw) begin
                                tx_shift_reg  <= tx_data;
                                sda_drive_low <= ~tx_data[7];
                                state         <= TGT_TX_DATA;
                            end else begin
                                data_shift_reg <= '0;
                                state          <= TGT_RX_DATA;
                            end
                        end
                    end

                    TGT_RX_DATA: begin
                        if (scl_rise) begin
                            data_byte      = {data_shift_reg[6:0], sda_sync};
                            data_shift_reg <= data_byte;

                            if (bit_cnt == 3'd7) begin
                                rx_data  <= data_byte;
                                rx_valid <= 1'b1;
                                bit_cnt  <= '0;
                                state    <= TGT_DATA_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    TGT_DATA_ACK: begin
                        if (scl_fall && !ack_active) begin
                            sda_drive_low <= 1'b1;
                            ack_active    <= 1'b1;
                        end else if (scl_fall && ack_active) begin
                            sda_drive_low <= 1'b0;
                            ack_active    <= 1'b0;
                            state         <= TGT_IGNORE;
                        end
                    end

                    TGT_TX_DATA: begin
                        if (scl_fall) begin
                            if (bit_cnt == 3'd7) begin
                                sda_drive_low <= 1'b0;
                                bit_cnt       <= '0;
                                state         <= TGT_WAIT_ACK;
                            end else begin
                                bit_cnt        <= bit_cnt + 1'b1;
                                tx_shift_reg   <= {tx_shift_reg[6:0], 1'b0};
                                sda_drive_low  <= ~tx_shift_reg[6];
                            end
                        end
                    end

                    TGT_WAIT_ACK: begin
                        if (scl_fall) begin
                            state <= TGT_IGNORE;
                        end
                    end

                    TGT_IGNORE: begin
                        sda_drive_low <= 1'b0;
                    end

                    default: state <= TGT_IDLE;
                endcase
            end
        end
    end

endmodule
