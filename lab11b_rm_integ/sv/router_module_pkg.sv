/*-----------------------------------------------------------------
File name     : router_module_pkg.sv
Description   : lab09_sbb router module UVC package
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// 把 Router Module UVC 的三个文件打包：
// 其他模块只需 import router_module_pkg::* 就能看到所有类型
package router_module_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 导入各接口 UVC 的 package，让本 package 能看到它们的事务类型
  import yapp_pkg::*;
  import channel_pkg::*;
  import hbus_pkg::*;

  // 9D：用 FIFO scoreboard 替代原来的 imp scoreboard + reference
  // router_fifo_scoreboard 内部已整合 reference 的过滤逻辑
  `include "router_fifo_scoreboard.sv"
  `include "router_module_env.sv"

endpackage : router_module_pkg
