/*-----------------------------------------------------------------
File name     : tb_top.sv
Description   : lab06_vif UVM top module
-----------------------------------------------------------------*/

module tb_top;
  // import the UVM library
  import uvm_pkg::*;

  // include the UVM macros
  `include "uvm_macros.svh"

  // import the YAPP package
  import yapp_pkg::*;
  import channel_pkg::*;
  import hbus_pkg::*;
  import clock_and_reset_pkg::*;
  // 6. import Router Module UVC package（包含 scoreboard/reference/env）
  import router_module_pkg::*;
  import cdns_uvm_addons::*;
  import yapp_router_reg_pkg::*;

  // include the testbench and test library
  `include "router_mcsequencer.sv"
  `include "router_mcseqs_lib.sv"
  `include "router_tb.sv"
  `include "router_test_lib.sv"
  `include "reset_test.sv"

  initial begin
    yapp_vif_config::set(null, "*.tb.yapp.tx_agent.*", "vif", hw_top.in0);
    hbus_vif_config::set(null, "*.tb.hbus.*", "vif", hw_top.hbus_if0);
    clock_and_reset_vif_config::set(null, "*.tb.clock_and_reset.*", "vif", hw_top.cr_if);
    channel_vif_config::set(null, "*.tb.chan0.*", "vif", hw_top.ch0_if);
    channel_vif_config::set(null, "*.tb.chan1.*", "vif", hw_top.ch1_if);
    channel_vif_config::set(null, "*.tb.chan2.*", "vif", hw_top.ch2_if);
    run_test();
  end

endmodule : tb_top
