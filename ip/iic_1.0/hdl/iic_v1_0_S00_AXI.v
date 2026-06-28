`timescale 1 ns / 1 ps

module iic_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN,
    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input  wire [                       2 : 0] S_AXI_AWPROT,
    input  wire                                S_AXI_AWVALID,
    output wire                                S_AXI_AWREADY,
    input  wire [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire                                S_AXI_WVALID,
    output wire                                S_AXI_WREADY,
    output wire [                       1 : 0] S_AXI_BRESP,
    output wire                                S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,
    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input  wire [                       2 : 0] S_AXI_ARPROT,
    input  wire                                S_AXI_ARVALID,
    output wire                                S_AXI_ARREADY,
    output wire [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [                       1 : 0] S_AXI_RRESP,
    output wire                                S_AXI_RVALID,
    input  wire                                S_AXI_RREADY,

    output wire                                start,
    output wire                                rw,
    output wire                                ack_in,
    output wire [                        15:0] clk_div,
    output wire [                         6:0] target_addr,
    output wire [                         7:0] tx_data,

    input  wire                                busy,
    input  wire                                done,
    input  wire                                ack_seen,
    input  wire [                         7:0] rx_data,
    output wire                                intr
);

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    localparam [C_S_AXI_DATA_WIDTH-1:0] CTRL_RESET   = 32'h0000_0004;
    localparam [C_S_AXI_DATA_WIDTH-1:0] CONFIG_RESET = 32'h0000_00FA;

    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg                            axi_awready;
    reg                            axi_wready;
    reg [                     1:0] axi_bresp;
    reg                            axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg                            axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [                     1:0] axi_rresp;
    reg                            axi_rvalid;

    reg [C_S_AXI_DATA_WIDTH-1:0] subordinate_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] subordinate_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] subordinate_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] subordinate_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;

    wire subordinate_reg_rden;
    wire subordinate_reg_wren;
    wire intr_i;

    integer byte_index;
    reg     aw_en;
    reg     start_pulse;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    assign start       = start_pulse;
    assign rw          = subordinate_reg0[1];
    assign ack_in      = subordinate_reg0[2];
    assign clk_div     = subordinate_reg1[15:0];
    assign target_addr = subordinate_reg1[22:16];
    assign tx_data     = subordinate_reg3[7:0];
    assign intr_i      = subordinate_reg0[3] & subordinate_reg2[1];
    assign intr        = intr_i;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
            axi_awaddr <= S_AXI_AWADDR;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    assign subordinate_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            subordinate_reg0 <= CTRL_RESET;
            subordinate_reg1 <= CONFIG_RESET;
            subordinate_reg2 <= 0;
            subordinate_reg3 <= 0;
            start_pulse      <= 1'b0;
        end else begin
            start_pulse <= 1'b0;

            subordinate_reg2[0]     <= busy;
            subordinate_reg2[2]     <= ack_seen;
            subordinate_reg2[3]     <= intr_i;
            subordinate_reg2[7:4]   <= 4'b0;
            subordinate_reg2[15:8]  <= rx_data;
            subordinate_reg2[31:16] <= 16'b0;
            subordinate_reg3[15:8]  <= rx_data;

            if (done) begin
                subordinate_reg2[1] <= 1'b1;
            end

            if (subordinate_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0: begin
                        if (S_AXI_WSTRB[0] == 1'b1) begin
                            subordinate_reg0[3:1] <= S_AXI_WDATA[3:1];
                            start_pulse           <= S_AXI_WDATA[0];
                            if (S_AXI_WDATA[4] == 1'b1) begin
                                subordinate_reg2[1] <= 1'b0;
                            end
                        end
                    end
                    2'h1: begin
                        for (
                            byte_index = 0;
                            byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                            byte_index = byte_index + 1
                        ) begin
                            if (S_AXI_WSTRB[byte_index] == 1'b1) begin
                                subordinate_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                        end
                    end
                    2'h3: begin
                        if (S_AXI_WSTRB[0] == 1'b1) begin
                            subordinate_reg3[7:0] <= S_AXI_WDATA[7:0];
                        end
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign subordinate_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0:    reg_data_out = subordinate_reg0;
            2'h1:    reg_data_out = subordinate_reg1;
            2'h2:    reg_data_out = subordinate_reg2;
            2'h3:    reg_data_out = subordinate_reg3;
            default: reg_data_out = 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else if (subordinate_reg_rden) begin
            axi_rdata <= reg_data_out;
        end
    end

endmodule
