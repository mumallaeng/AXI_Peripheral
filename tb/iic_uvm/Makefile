VCS_OPTS  = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert
VCS_OPTS += -cm_hier cm_hier.cfg

VCS_INCDIR = +incdir+.

VCS_SRC_FILES  = ../../ip/iic_1.0/hdl/iic_controller.sv
VCS_SRC_FILES += ../../ip/iic_1.0/hdl/iic_v1_0_S00_AXI.v
VCS_SRC_FILES += ../../ip/iic_1.0/hdl/iic_v1_0.v
VCS_SRC_FILES += ./rtl_iic_target_model.sv
VCS_SRC_FILES += ./iic_if.sv
VCS_SRC_FILES += ./iic_pkg.sv
VCS_SRC_FILES += ./tb_top.sv

TEST       ?= iic_all_test
INFO_LEVEL ?= UVM_LOW
SEED       ?= 1
NUM        ?= 300
RUN_TAG    ?= $(TEST)_seed$(SEED)
REPORT_DIR ?= results/$(RUN_TAG)/cov_report

SIMV_OPTS  = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)
SIMV_OPTS += +NUM=$(NUM)
SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_dir coverage.vdb
SIMV_OPTS += -cm_name sim_$(RUN_TAG)

.PHONY: all comp simv cov run clean

all: run

comp:
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES) -o simv -l comp.log

simv: comp
	mkdir -p results/$(RUN_TAG)
	./simv $(SIMV_OPTS) -l results/$(RUN_TAG)/sim.log

cov:
	mkdir -p results/$(RUN_TAG)
	urg -dir simv.vdb coverage.vdb -report $(REPORT_DIR)
	cp comp.log results/$(RUN_TAG)/comp.log.txt
	cp results/$(RUN_TAG)/sim.log results/$(RUN_TAG)/sim.log.txt
	@echo "Coverage report: $(REPORT_DIR)/dashboard.html"

run: simv cov

clean:
	rm -rf simv simv.daidir csrc coverage.vdb results \
	       *.log *.key *.h *.fsdb novas* verdiLog AN.DB DVEfiles ucli.key
