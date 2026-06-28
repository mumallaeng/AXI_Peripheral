class iic_base_test extends uvm_test;
    `uvm_component_utils(iic_base_test)

    iic_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = iic_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass

class iic_axi_test extends iic_base_test;
    `uvm_component_utils(iic_axi_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        iic_axi_seq seq;
        seq = iic_axi_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

class iic_peripheral_test extends iic_base_test;
    `uvm_component_utils(iic_peripheral_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        iic_peripheral_seq seq;
        seq = iic_peripheral_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

class iic_protocol_test extends iic_base_test;
    `uvm_component_utils(iic_protocol_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        iic_protocol_seq seq;
        seq = iic_protocol_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

class iic_random_test extends iic_base_test;
    `uvm_component_utils(iic_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        iic_random_seq seq;
        seq = iic_random_seq::type_id::create("seq");
        phase.raise_objection(this);
        if (!seq.randomize())
            `uvm_error("TEST", "randomize failed")
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

class iic_all_test extends iic_base_test;
    `uvm_component_utils(iic_all_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        iic_axi_seq        axi_seq;
        iic_peripheral_seq peri_seq;
        iic_protocol_seq   proto_seq;
        iic_random_seq     rand_seq;

        axi_seq   = iic_axi_seq::type_id::create("axi_seq");
        peri_seq  = iic_peripheral_seq::type_id::create("peri_seq");
        proto_seq = iic_protocol_seq::type_id::create("proto_seq");
        rand_seq  = iic_random_seq::type_id::create("rand_seq");

        phase.raise_objection(this);
        axi_seq.start(env.agt.sqr);
        peri_seq.start(env.agt.sqr);
        proto_seq.start(env.agt.sqr);
        if (!rand_seq.randomize())
            `uvm_error("TEST", "randomize failed")
        rand_seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass
