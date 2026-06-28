class iic_env extends uvm_env;
    `uvm_component_utils(iic_env)

    iic_agent agt;
    iic_scoreboard scb;
    iic_coverage cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = iic_agent::type_id::create("agt", this);
        scb = iic_scoreboard::type_id::create("scb", this);
        cov = iic_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.drv.expected_ap.connect(scb.expected_imp);
        agt.mon.ap.connect(scb.observed_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass
