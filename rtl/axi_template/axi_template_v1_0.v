
`timescale 1 ns / 1 ps

	module axi_template_v1_0 #
	(
		parameter integer C_S00_AXI_DATA_WIDTH	= 32, // S00_AXI 데이터 버스 폭
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4   // S00_AXI 주소 버스 폭
	)
	(
		input wire  s00_axi_aclk,                                           // AXI 클록
		input wire  s00_axi_aresetn,                                        // 낮은 레벨에서 활성화되는 AXI reset
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,             // 쓰기 주소
		input wire [2 : 0] s00_axi_awprot,                                  // 쓰기 보호 속성
		input wire  s00_axi_awvalid,                                        // 쓰기 주소 유효 표시
		output wire  s00_axi_awready,                                       // 쓰기 주소 수신 가능 표시
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,              // 쓰기 데이터
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,          // byte lane별 쓰기 enable
		input wire  s00_axi_wvalid,                                         // 쓰기 데이터 유효 표시
		output wire  s00_axi_wready,                                        // 쓰기 데이터 수신 가능 표시
		output wire [1 : 0] s00_axi_bresp,                                  // 쓰기 응답 코드
		output wire  s00_axi_bvalid,                                        // 쓰기 응답 유효 표시
		input wire  s00_axi_bready,                                         // 쓰기 응답 수신 가능 표시
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,             // 읽기 주소
		input wire [2 : 0] s00_axi_arprot,                                  // 읽기 보호 속성
		input wire  s00_axi_arvalid,                                        // 읽기 주소 유효 표시
		output wire  s00_axi_arready,                                       // 읽기 주소 수신 가능 표시
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,             // 읽기 데이터
		output wire [1 : 0] s00_axi_rresp,                                  // 읽기 응답 코드
		output wire  s00_axi_rvalid,                                        // 읽기 데이터 유효 표시
		input wire  s00_axi_rready                                          // 읽기 데이터 수신 가능 표시
	);

	// S00_AXI slave interface 실제 동작은 하위 모듈에서 처리한다.
	axi_template_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi_template_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	endmodule
