/*-----------------------------------------------------------------
File name     : router_tb.sv
Description   : lab02_test router testbench
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

class router_tb extends uvm_env;

  yapp_router_regs_t  yapp_rm;
  hbus_reg_adapter    reg2hbus;

  `uvm_component_utils_begin(router_tb)
    `uvm_field_object(yapp_rm, UVM_ALL_ON)
  `uvm_component_utils_end

  yapp_env yapp;

  channel_env chan0;
  channel_env chan1;
  channel_env chan2;

  hbus_env          hbus;
  clock_and_reset_env clock_and_reset;

  router_mcsequencer mcseqr;

  // 5a. 用 router_env (Router Module UVC) 替换裸露的 router_scoreboard
  router_env router_mod;

  function new(string name, uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    yapp = yapp_env::type_id::create("yapp", this);
    uvm_config_int::set(this, "chan0", "channel_id", 0);
    uvm_config_int::set(this, "chan1", "channel_id", 1);
    uvm_config_int::set(this, "chan2", "channel_id", 2);
    chan0 = channel_env::type_id::create("chan0", this);
    chan1 = channel_env::type_id::create("chan1", this);
    chan2 = channel_env::type_id::create("chan2", this);
    uvm_config_int::set(this, "hbus", "num_masters", 1);
    uvm_config_int::set(this, "hbus", "num_slaves",  0);
    hbus          = hbus_env::type_id::create("hbus", this);
    clock_and_reset = clock_and_reset_env::type_id::create("clock_and_reset", this);
    mcseqr = router_mcsequencer::type_id::create("mcseqr", this);
    // 5a. 实例化 router_env 替代原来的裸 scoreboard
    router_mod = router_env::type_id::create("router_mod", this);
    // RAL 模型
    yapp_rm = yapp_router_regs_t::type_id::create("yapp_rm", this);
    yapp_rm.build();
    yapp_rm.lock_model();
    yapp_rm.set_hdl_path_root("hw_top.dut");
    yapp_rm.default_map.set_auto_predict(1);
    // HBUS adapter
    reg2hbus = hbus_reg_adapter::type_id::create("reg2hbus", this);
    `uvm_info("MSG", "Testbench build phase executed", UVM_HIGH)
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    mcseqr.yapp_seqr = yapp.tx_agent.sequencer;
    mcseqr.hbus_seqr = hbus.masters[0].sequencer;
    yapp_rm.default_map.set_sequencer(hbus.masters[0].sequencer, reg2hbus);
    // 9C: 现在只连接 router_mod 顶层的 export，不再穿透访问内部子组件
    // testbench 不需要知道 reference 或 scoreboard 的存在
    yapp.tx_agent.monitor.item_collected_port.connect(router_mod.yapp_in);
    hbus.masters[0].monitor.item_collected_port.connect(router_mod.hbus_in);
    chan0.rx_agent.monitor.item_collected_port.connect(router_mod.chan0_in);
    chan1.rx_agent.monitor.item_collected_port.connect(router_mod.chan1_in);
    chan2.rx_agent.monitor.item_collected_port.connect(router_mod.chan2_in);
  endfunction : connect_phase

  function void start_of_simulation_phase(uvm_phase phase);
    `uvm_info(get_type_name(), {"start_of_simulation for ", get_full_name()}, UVM_HIGH)
  endfunction : start_of_simulation_phase

endclass : router_tb
