// 이 환경에서는 driver가 AXI 트랜잭션을 완결하고 결과를 req에 채운 뒤
// analysis port로 broadcast 한다. monitor는 그 통로 역할.
// (AXI BFM 기반 검증에서 흔한 driver-publish 패턴 — 핀 race 없음)
//
// 별도의 독립 monitor가 필요하면 cs_n/sclk 핀을 직접 디코드하도록
// 확장할 수 있으나, 본 환경은 레지스터 인터페이스 정합성 검증이 목적이므로
// driver가 read한 RXDATA / slave 모델 출력을 신뢰값으로 사용한다.
class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
endclass