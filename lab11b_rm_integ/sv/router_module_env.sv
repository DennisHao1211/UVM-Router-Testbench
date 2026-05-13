/*-----------------------------------------------------------------
File name     : router_module_env.sv
Description   : lab09_sbb router module UVC environment
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// Router Module UVC（Lab 9D FIFO 版）
// 相比 9C，去掉了独立的 router_reference 组件
// reference 的过滤逻辑已整合进 router_fifo_scoreboard 的 run_phase task
class router_env extends uvm_env;

  // 唯一子组件：FIFO 版 scoreboard（内含 reference 逻辑）
  router_fifo_scoreboard scoreboard;

  // 顶层 export：对外黑盒接口，与 9C 完全相同
  // 外部 testbench 连这里，不需要知道内部用了 FIFO 还是 imp
  uvm_analysis_export #(yapp_packet)      yapp_in;
  uvm_analysis_export #(hbus_transaction) hbus_in;
  uvm_analysis_export #(channel_packet)   chan0_in;
  uvm_analysis_export #(channel_packet)   chan1_in;
  uvm_analysis_export #(channel_packet)   chan2_in;

  `uvm_component_utils(router_env)

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    yapp_in  = new("yapp_in",  this);
    hbus_in  = new("hbus_in",  this);
    chan0_in = new("chan0_in", this);
    chan1_in = new("chan1_in", this);
    chan2_in = new("chan2_in", this);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard = router_fifo_scoreboard::type_id::create("scoreboard", this);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    // export.connect(fifo.analysis_export)
    // fifo.analysis_export 本质是 uvm_analysis_imp，接受 write() 调用并入队
    // 与 9C 的 export.connect(imp) 完全等价，只是 imp 藏在 FIFO 内部
    yapp_in.connect(scoreboard.yapp_fifo.analysis_export);
    hbus_in.connect(scoreboard.hbus_fifo.analysis_export);
    chan0_in.connect(scoreboard.chan0_fifo.analysis_export);
    chan1_in.connect(scoreboard.chan1_fifo.analysis_export);
    chan2_in.connect(scoreboard.chan2_fifo.analysis_export);
  endfunction : connect_phase

endclass : router_env
