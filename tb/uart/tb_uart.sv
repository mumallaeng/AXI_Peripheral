
`timescale 1ns / 1ps

module tb_uart ();


    logic clk, reset_n;

    logic [31:0] TDR, RDR, CR, SR;

    logic        w_loop;

    logic        tx;
    logic        rx;
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




    uart_v1_0 dut (
        .*,
        .tx(w_loop),
        .rx(w_loop)
    );

    assign s00_axi_aclk = clk;
    assign s00_axi_aresetn = reset_n;

    initial clk = 0;
    always #5 clk = ~clk;

    localparam UART_SR_ADDR = 32'h00000000;
    localparam UART_TDR_ADDR = 32'h00000004;
    localparam UART_RDR_ADDR = 32'h00000008;
    localparam UART_CR_ADDR = 32'h0000000C;

    task automatic AXI_WriteData(logic [31:0] addr, logic [31:0] data);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;
        s00_axi_wstrb   <= 4'b1111;  // 이게 없으면 동작 않함
        @(posedge clk);
        wait (s00_axi_awready & s00_axi_wready) @(posedge clk);
        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;
        @(posedge clk);
        wait (s00_axi_bvalid);
        @(posedge clk);
        s00_axi_bready <= 1'b0;
        @(posedge clk);
    endtask

    task automatic AXI_ReadData(input logic [31:0] addr,
                                output logic [31:0] rdata);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;
        @(posedge clk);
        wait (s00_axi_arready);
        @(posedge clk);
        s00_axi_arvalid <= 1'b0;
        wait (s00_axi_rvalid);
        @(posedge clk);
        s00_axi_rready <= 1'b0;
        rdata = s00_axi_rdata;
        @(posedge clk);
    endtask  //automatic

    initial begin
        reset_n = 0;
        CR = 0;
        TDR = 0;
        RDR = 0;
        SR = 0;


        repeat (5) @(posedge clk);
        reset_n = 1;
        @(posedge clk);

        CR |= (1 << 0);
        AXI_WriteData(UART_CR_ADDR, CR);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'haa;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 1)));
        AXI_ReadData(UART_RDR_ADDR, RDR);


        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h55;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 1)));
        AXI_ReadData(UART_RDR_ADDR, RDR);


        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h12;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 1)));
        AXI_ReadData(UART_RDR_ADDR, RDR);



        //intr

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h34;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(UART_RDR_ADDR, RDR);
        @(posedge clk);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h11;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(UART_RDR_ADDR, RDR);
        // wait (intr);
        @(posedge clk);

        do begin
            AXI_ReadData(UART_SR_ADDR, SR);
        end while (!(SR & (1 << 0)));
        TDR = 8'h22;
        AXI_WriteData(UART_TDR_ADDR, TDR);
        wait (intr);
        @(posedge clk);
        AXI_ReadData(UART_RDR_ADDR, RDR);
        #30000;



        #1000;
        $finish;


    end



endmodule
