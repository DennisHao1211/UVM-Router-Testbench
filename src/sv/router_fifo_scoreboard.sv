// Lab 9D: FIFO-based scoreboard
// 与 imp-based 版本的根本区别：
//   imp 版本：monitor 调 write() -> 立即执行比较（被动回调）
//   FIFO 版本：monitor 调 write() -> 数据入队，run_phase task 主动消费（异步处理）

class router_fifo_scoreboard extends uvm_scoreboard;

  // -----------------------------------------------------------------------
  // Step 2a: Analysis FIFOs
  // uvm_tlm_analysis_fifo 内部有一个 analysis_export（本质是 imp）
  // 接受 monitor 的 write() 调用，把事务放入队列缓冲
  // -----------------------------------------------------------------------
  uvm_tlm_analysis_fifo #(yapp_packet)      yapp_fifo;
  uvm_tlm_analysis_fifo #(hbus_transaction) hbus_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan0_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan1_fifo;
  uvm_tlm_analysis_fifo #(channel_packet)   chan2_fifo;

  // -----------------------------------------------------------------------
  // Step 2b: Get ports
  // run_phase task 通过这些 port 做阻塞读（blocking get）
  // 在 connect_phase 连接到各 FIFO 的 get_peek_export
  // -----------------------------------------------------------------------
  uvm_get_port #(yapp_packet)      yapp_get;
  uvm_get_port #(hbus_transaction) hbus_get;
  uvm_get_port #(channel_packet)   chan0_get;
  uvm_get_port #(channel_packet)   chan1_get;
  uvm_get_port #(channel_packet)   chan2_get;

  // 镜像寄存器：由 monitor_hbus task 实时更新
  bit [7:0] max_pktsize_reg   = 8'h3F;
  bit [7:0] router_enable_reg = 8'h01;

  // 统计计数器
  int packets_in,  in_dropped;
  int packets_ch0, compare_ch0, miscompare_ch0;
  int packets_ch1, compare_ch1, miscompare_ch1;
  int packets_ch2, compare_ch2, miscompare_ch2;

  `uvm_component_utils(router_fifo_scoreboard)

  function new(string name="", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // FIFOs 和 ports 都是 uvm_component，在 build_phase 实例化
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    yapp_fifo  = new("yapp_fifo",  this);
    hbus_fifo  = new("hbus_fifo",  this);
    chan0_fifo  = new("chan0_fifo", this);
    chan1_fifo  = new("chan1_fifo", this);
    chan2_fifo  = new("chan2_fifo", this);
    yapp_get  = new("yapp_get",  this);
    hbus_get  = new("hbus_get",  this);
    chan0_get  = new("chan0_get", this);
    chan1_get  = new("chan1_get", this);
    chan2_get  = new("chan2_get", this);
  endfunction

  // get_port.connect(fifo.get_peek_export)
  // 把读取端口连到对应 FIFO 的输出口
  function void connect_phase(uvm_phase phase);
    yapp_get.connect(yapp_fifo.get_peek_export);
    hbus_get.connect(hbus_fifo.get_peek_export);
    chan0_get.connect(chan0_fifo.get_peek_export);
    chan1_get.connect(chan1_fifo.get_peek_export);
    chan2_get.connect(chan2_fifo.get_peek_export);
  endfunction

  // -----------------------------------------------------------------------
  // Step 2c: run_phase
  // 主动消费 FIFO 里的事务，而不是等 write() 回调
  // -----------------------------------------------------------------------

  // 并发子任务：持续消费 HBUS FIFO，更新寄存器镜像
  // 这是 reference model 逻辑在 9D 中的替代
  task monitor_hbus();
    hbus_transaction hbus_cmd;
    forever begin
      hbus_get.get(hbus_cmd);  // 阻塞，直到 HBUS FIFO 有数据
      `uvm_info(get_type_name(),
        $sformatf("HBUS Transaction:\n%s", hbus_cmd.sprint()), UVM_MEDIUM)
      if (hbus_cmd.hwr_rd == HBUS_WRITE)
        case (hbus_cmd.haddr)
          16'h1000 : max_pktsize_reg   = hbus_cmd.hdata;
          16'h1001 : router_enable_reg = hbus_cmd.hdata;
        endcase
    end
  endtask

  task run_phase(uvm_phase phase);
    yapp_packet    yapp_pkt;
    channel_packet chan_pkt;

    // fork 出 HBUS 监控 task，与主循环并发运行
    // join_none 让主线程立即继续，两者同时跑
    fork
      monitor_hbus();
    join_none

    // 主循环：阻塞等待 YAPP FIFO 有包，然后做过滤和比较
    forever begin
      yapp_get.get(yapp_pkt);  // 阻塞，直到 YAPP FIFO 有数据
      packets_in++;
      `uvm_info(get_type_name(),
        $sformatf("Received YAPP Packet:\n%s", yapp_pkt.sprint()), UVM_LOW)

      // 过滤1：路由器未使能
      if (router_enable_reg == 0) begin
        in_dropped++;
        `uvm_info(get_type_name(), "Packet dropped [ROUTER DISABLED]", UVM_LOW)
        continue;
      end

      // 过滤2：非法地址（addr==3）
      if (yapp_pkt.addr == 2'b11) begin
        in_dropped++;
        `uvm_info(get_type_name(), "Packet dropped [BAD ADDRESS]", UVM_LOW)
        continue;
      end

      // 过滤3：包长超出限制
      if (yapp_pkt.length > max_pktsize_reg) begin
        in_dropped++;
        `uvm_info(get_type_name(),
          $sformatf("Packet dropped [OVERSIZED] len=%0h max=%0h",
            yapp_pkt.length, max_pktsize_reg), UVM_LOW)
        continue;
      end

      // 合法包：从对应 channel FIFO 取出期望包并比较
      case (yapp_pkt.addr)
        2'b00: begin
          packets_ch0++;
          chan0_get.get(chan_pkt);  // 阻塞等 chan0 FIFO 有数据
          if (comp_equal(yapp_pkt, chan_pkt)) begin
            compare_ch0++;
            `uvm_info(get_type_name(), $sformatf("Match: Chan0\n%s", chan_pkt.sprint()), UVM_MEDIUM)
          end else miscompare_ch0++;
        end
        2'b01: begin
          packets_ch1++;
          chan1_get.get(chan_pkt);
          if (comp_equal(yapp_pkt, chan_pkt)) begin
            compare_ch1++;
            `uvm_info(get_type_name(), $sformatf("Match: Chan1\n%s", chan_pkt.sprint()), UVM_MEDIUM)
          end else miscompare_ch1++;
        end
        2'b10: begin
          packets_ch2++;
          chan2_get.get(chan_pkt);
          if (comp_equal(yapp_pkt, chan_pkt)) begin
            compare_ch2++;
            `uvm_info(get_type_name(), $sformatf("Match: Chan2\n%s", chan_pkt.sprint()), UVM_MEDIUM)
          end else miscompare_ch2++;
        end
      endcase
    end
  endtask

  // 字段级比较：返回 1 表示匹配
  function bit comp_equal(input yapp_packet yp, input channel_packet cp);
    if (yp.addr != cp.addr) begin
      `uvm_error("PKT_COMPARE", $sformatf("Addr mismatch YAPP=%0d Chan=%0d", yp.addr, cp.addr))
      return 0;
    end
    if (yp.length != cp.length) begin
      `uvm_error("PKT_COMPARE", $sformatf("Length mismatch YAPP=%0d Chan=%0d", yp.length, cp.length))
      return 0;
    end
    foreach (yp.payload[i])
      if (yp.payload[i] != cp.payload[i]) begin
        `uvm_error("PKT_COMPARE", $sformatf("Payload[%0d] mismatch", i))
        return 0;
      end
    if (yp.parity != cp.parity) begin
      `uvm_error("PKT_COMPARE", "Parity mismatch")
      return 0;
    end
    return 1;
  endfunction

  // -----------------------------------------------------------------------
  // Step 2d: check_phase
  // run_phase 结束后，所有 channel FIFO 应该为空
  // -----------------------------------------------------------------------
  function void check_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "Checking Router FIFO Scoreboard", UVM_LOW)
    if (chan0_fifo.size() || chan1_fifo.size() || chan2_fifo.size())
      `uvm_error(get_type_name(),
        $sformatf("Channel FIFOs NOT empty: Chan0=%0d  Chan1=%0d  Chan2=%0d",
          chan0_fifo.size(), chan1_fifo.size(), chan2_fifo.size()))
    else
      `uvm_info(get_type_name(), "All channel FIFOs empty - OK", UVM_LOW)
  endfunction

  // Step 2e: report_phase
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf(
      "\n  FIFO Scoreboard Statistics\n    Pkts In=%0d  Dropped=%0d\n    Ch0: total=%0d pass=%0d mismatch=%0d\n    Ch1: total=%0d pass=%0d mismatch=%0d\n    Ch2: total=%0d pass=%0d mismatch=%0d",
      packets_in, in_dropped,
      packets_ch0, compare_ch0, miscompare_ch0,
      packets_ch1, compare_ch1, miscompare_ch1,
      packets_ch2, compare_ch2, miscompare_ch2), UVM_LOW)
    if ((miscompare_ch0 + miscompare_ch1 + miscompare_ch2) > 0)
      `uvm_error(get_type_name(), "Status: Simulation FAILED")
    else
      `uvm_info(get_type_name(), "Status: Simulation PASSED", UVM_NONE)
  endfunction

endclass : router_fifo_scoreboard
