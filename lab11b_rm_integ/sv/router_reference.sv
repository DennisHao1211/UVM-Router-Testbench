/*-----------------------------------------------------------------
File name     : router_reference.sv
Description   : lab09_sbb router module UVC reference model
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// 3a. 继承自 uvm_component（参考模型是无源被动组件，不需要 sequence/driver）
class router_reference extends uvm_component;

  // 3b. 同一组件有两个 analysis imp，必须用宏生成带后缀的唯一 imp 类型
  //     否则两个 write() 会冲突
  `uvm_analysis_imp_decl(_hbus)
  `uvm_analysis_imp_decl(_yapp)

  // 3b. 两个输入 imp：连接到 HBUS monitor 和 YAPP monitor 的 analysis port
  uvm_analysis_imp_hbus #(hbus_transaction, router_reference) hbus_in;
  uvm_analysis_imp_yapp #(yapp_packet,      router_reference) yapp_in;

  // 3c. 输出 analysis port：将合法 YAPP 包写给 scoreboard 的 sb_yapp_in
  uvm_analysis_port #(yapp_packet) sb_add_out;

  // 3d. 镜像寄存器：与 DUT 内部寄存器保持同步
  //     DUT 地址 0x1000 = maxpktsize，0x1001 = router_enable
  bit [7:0] max_pktsize_reg   = 8'h3F;  // 默认最大包长 63 字节
  bit [7:0] router_enable_reg = 8'h01;  // 默认路由器使能

  // 3e. 统计计数器：分别记录三种丢包原因
  int packets_forwarded = 0;
  int packets_dropped   = 0;
  int jumbo_packets     = 0;   // 超出 maxpktsize 的包
  int bad_addr_packets  = 0;   // addr==3 非法地址

  `uvm_component_utils(router_reference)

  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    hbus_in    = new("hbus_in",    this);
    yapp_in    = new("yapp_in",    this);
    sb_add_out = new("sb_add_out", this);
  endfunction : new

  // 3d. HBUS write 实现：捕获寄存器写操作，更新镜像值
  //     只关心 HBUS_WRITE 事务，HBUS_READ 不影响 DUT 状态
  function void write_hbus(hbus_transaction hbus_cmd);
    `uvm_info(get_type_name(),
      $sformatf("Received HBUS Transaction:\n%s", hbus_cmd.sprint()), UVM_MEDIUM)
    if (hbus_cmd.hwr_rd == HBUS_WRITE)
      case (hbus_cmd.haddr)
        16'h1000 : max_pktsize_reg   = hbus_cmd.hdata;
        16'h1001 : router_enable_reg = hbus_cmd.hdata;
      endcase
  endfunction : write_hbus

  // 3e. YAPP write 实现：根据当前寄存器状态过滤包
  //     只有通过全部检查的包才通过 sb_add_out 转发给 scoreboard
  function void write_yapp(yapp_packet packet);
    `uvm_info(get_type_name(),
      $sformatf("Received YAPP Packet:\n%s", packet.sprint()), UVM_LOW)

    if (packet.addr == 2'b11) begin
      // addr=3 是广播/非法地址，DUT 直接丢弃
      bad_addr_packets++;
      packets_dropped++;
      `uvm_info(get_type_name(), "YAPP Packet Dropped [BAD ADDRESS]", UVM_LOW)
    end
    else if (router_enable_reg == 0) begin
      // router_en 寄存器为 0，路由器禁用，所有包丢弃
      packets_dropped++;
      `uvm_info(get_type_name(), "YAPP Packet Dropped [DISABLED]", UVM_LOW)
    end
    else if (packet.length > max_pktsize_reg) begin
      // 包长超过 maxpktsize 寄存器，DUT 丢弃超大包
      jumbo_packets++;
      packets_dropped++;
      `uvm_info(get_type_name(),
        $sformatf("YAPP Packet Dropped [OVERSIZED] pkt_len=%0h max=%0h",
          packet.length, max_pktsize_reg), UVM_LOW)
    end
    else begin
      // 合法包：路由器使能 + 地址有效 + 长度合法，转发给 scoreboard
      sb_add_out.write(packet);
      packets_forwarded++;
      `uvm_info(get_type_name(), "Sent YAPP Packet to Scoreboard", UVM_LOW)
    end
  endfunction : write_yapp

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf(
      "Report: Router Reference\n  Forwarded=%0d  Dropped=%0d  Oversized=%0d  BadAddr=%0d",
      packets_forwarded, packets_dropped, jumbo_packets, bad_addr_packets), UVM_LOW)
  endfunction : report_phase

endclass : router_reference
