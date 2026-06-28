class spi_base_test extends uvm_test; //
    `uvm_component_utils(spi_base_test)
    spi_env env;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass

// 4모드 전부 sweep
class spi_mode_test extends spi_base_test;
    `uvm_component_utils(spi_mode_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        spi_mode_seq seq = spi_mode_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

class spi_random_test extends spi_base_test;
    `uvm_component_utils(spi_random_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        spi_random_seq seq = spi_random_seq::type_id::create("seq");
        phase.raise_objection(this);
        if (!seq.randomize()) `uvm_error("TEST", "randomize fail")
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

// 전체: mode sweep + full + random
class spi_all_test extends spi_base_test;
    `uvm_component_utils(spi_all_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        spi_mode_seq   s_mode = spi_mode_seq::type_id::create("s_mode");
        spi_full_seq   s_full = spi_full_seq::type_id::create("s_full");
        spi_random_seq s_rand = spi_random_seq::type_id::create("s_rand");
        phase.raise_objection(this);
        if (!s_rand.randomize()) `uvm_error("TEST", "randomize fail")
        s_mode.start(env.agt.sqr);
        s_full.start(env.agt.sqr);
        s_rand.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass