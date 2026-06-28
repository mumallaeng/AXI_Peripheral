# ============================================================
#  SPI AXI Controller — UVM 검증 Makefile (VCS)
# ============================================================

VCS_OPTS  = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert

VCS_INCDIR = +incdir+tb +incdir+rtl

VCS_OUTPUT = -o simv

# ── 소스 파일 (컴파일 순서 주의) ──────────────────────────
#  1) DUT (Verilog) — 하위 모듈이 먼저 와도 VCS는 elaboration에서 해결하나
#     명시적으로 top → 하위 순서로 둠
#  2) TB SPI slave 모델
#  3) UVM interface / package
#  4) tb_top
VCS_SRC_FILES  = ../../ip/spi_1.0/hdl/spi_controller.sv
VCS_SRC_FILES += ../../ip/spi_1.0/hdl/spi_controller_top.v
VCS_SRC_FILES += ../../ip/spi_1.0/hdl/spi_v1_0_S00_AXI.v
VCS_SRC_FILES += ../../ip/spi_1.0/hdl/spi_v1_0.v
VCS_SRC_FILES += ./rtl_spi_target_model.sv
VCS_SRC_FILES += ./spi_if.sv
VCS_SRC_FILES += ./spi_pkg.sv
VCS_SRC_FILES += ./tb_top.sv

TEST       ?= spi_all_test
INFO_LEVEL ?= UVM_LOW
SEED       ?= 1

SIMV_OPTS  = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)
SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_dir coverage.vdb
SIMV_OPTS += -cm_name sim_$(TEST)

.PHONY: all comp simv verdi cov clean

all : simv

comp:
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) $(VCS_OUTPUT) -l comp.log
	@echo "타겟 [$@] 완료"

simv: comp
	./simv $(SIMV_OPTS) -l sim_$(TEST).log
	@echo "의존 타겟 [$<]"
	@echo "타겟 [$@] 완료 → sim_$(TEST).log 확인"

# 파형 보기 (fsdb → Verdi)
verdi:
	verdi -ssf spi_axi_tb.fsdb &

# 커버리지 리포트
cov:
	urg -dir coverage.vdb -report cov_report
	@echo "커버리지 리포트 → cov_report/ 확인"

clean:
	rm -rf simv* csrc *.log *.key *.h *.fsdb \
	       coverage.vdb cov_report novas* verdiLog AN.DB DVEfiles ucli.key
	@echo "결과물 정리 중 ..."