/*-----------------------------------------------------------------
File name     : router_test_lib.sv
Description   : lab02_test router test library
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  router_tb tb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function bit use_default_sequence();
    return 1;
  endfunction : use_default_sequence

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (use_default_sequence()) begin
      uvm_config_wrapper::set(this,
                              "tb.yapp.tx_agent.sequencer.run_phase",
                              "default_sequence",
                              yapp_5_packets::get_type());
    end
    uvm_config_int::set(this, "*", "recording_detail", 1);
    tb = router_tb::type_id::create("tb", this);
    `uvm_info("MSG", "Test build phase executed", UVM_HIGH)
  endfunction : build_phase

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  task run_phase(uvm_phase phase);
    uvm_objection obj = phase.get_objection();
    obj.set_drain_time(this, 2000ns);
  endtask : run_phase

  function void check_phase(uvm_phase phase);
    check_config_usage();
  endfunction : check_phase

endclass : base_test

// class test2 extends base_test;
//   `uvm_component_utils(test2)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
// endclass : test2

// class short_packet_test extends base_test;
//   `uvm_component_utils(short_packet_test)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
//   function void build_phase(uvm_phase phase);
//     yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
//     super.build_phase(phase);
//   endfunction : build_phase
// endclass : short_packet_test

// class set_config_test extends base_test;
//   `uvm_component_utils(set_config_test)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
//   virtual function bit use_default_sequence();
//     return 0;
//   endfunction : use_default_sequence
//   function void build_phase(uvm_phase phase);
//     uvm_config_int::set(this, "tb.yapp.tx_agent", "is_active", UVM_PASSIVE);
//     super.build_phase(phase);
//   endfunction : build_phase
// endclass : set_config_test

// class incr_payload_test extends base_test;
//   `uvm_component_utils(incr_payload_test)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
//   virtual function bit use_default_sequence();
//     return 0;
//   endfunction : use_default_sequence
//   function void build_phase(uvm_phase phase);
//     yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
//     uvm_config_wrapper::set(this,
//                             "tb.yapp.tx_agent.sequencer.run_phase",
//                             "default_sequence",
//                             yapp_incr_payload_seq::get_type());
//     super.build_phase(phase);
//   endfunction : build_phase
// endclass : incr_payload_test

// class exhaustive_seq_test extends base_test;
//   `uvm_component_utils(exhaustive_seq_test)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
//   virtual function bit use_default_sequence();
//     return 0;
//   endfunction : use_default_sequence
//   function void build_phase(uvm_phase phase);
//     yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
//     uvm_config_wrapper::set(this,
//                             "tb.yapp.tx_agent.sequencer.run_phase",
//                             "default_sequence",
//                             yapp_exhaustive_seq::get_type());
//     super.build_phase(phase);
//   endfunction : build_phase
// endclass : exhaustive_seq_test

// class short_yapp_012 extends base_test;
//   `uvm_component_utils(short_yapp_012)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
//   virtual function bit use_default_sequence();
//     return 0;
//   endfunction : use_default_sequence
//   function void build_phase(uvm_phase phase);
//     yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
//     uvm_config_wrapper::set(this,
//                             "tb.yapp.tx_agent.sequencer.run_phase",
//                             "default_sequence",
//                             yapp_012_seq::get_type());
//     super.build_phase(phase);
//   endfunction : build_phase
// endclass : short_yapp_012

// class yapp_012_test extends short_yapp_012;
//   `uvm_component_utils(yapp_012_test)
//   function new(string name, uvm_component parent);
//     super.new(name, parent);
//   endfunction : new
// endclass : yapp_012_test

class simple_test extends base_test;

  `uvm_component_utils(simple_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function void build_phase(uvm_phase phase);
    // a. short packet 类型覆盖
    yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
    // b. YAPP 默认 sequence
    uvm_config_wrapper::set(this, "tb.yapp.tx_agent.sequencer.run_phase",
                            "default_sequence", yapp_012_seq::get_type());
    // c. 三个 Channel 用通配符一条语句覆盖
    uvm_config_wrapper::set(this, "tb.chan*.rx_agent.sequencer.run_phase",
                            "default_sequence", channel_rx_resp_seq::get_type());
    // d. Clock and Reset 默认 sequence
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    // e. HBUS 不设 sequence
    super.build_phase(phase);
  endfunction : build_phase

endclass : simple_test

class test_uvc_integration extends base_test;

  `uvm_component_utils(test_uvc_integration)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function void build_phase(uvm_phase phase);
    // Clock and Reset
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    // Channel UVCs
    uvm_config_wrapper::set(this, "tb.chan*.rx_agent.sequencer.run_phase",
                            "default_sequence", channel_rx_resp_seq::get_type());
    // a. YAPP: 88 packets, all addresses, incrementing payload, 20% bad parity
    uvm_config_wrapper::set(this, "tb.yapp.tx_agent.sequencer.run_phase",
                            "default_sequence", yapp_all_channels_seq::get_type());
    // b. HBUS: maxpktsize=20, router_en=1
    uvm_config_wrapper::set(this, "tb.hbus.masters[0].sequencer.run_phase",
                            "default_sequence", hbus_small_packet_seq::get_type());
    super.build_phase(phase);
  endfunction : build_phase

endclass : test_uvc_integration

class router_mcseq_test extends base_test;

  `uvm_component_utils(router_mcseq_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function void build_phase(uvm_phase phase);
    // a. Short packet type override -- commented out for Step 7 mismatch test
    // yapp_packet::type_id::set_type_override(short_yapp_packet::get_type());
    // b. Channel UVCs response sequences
    uvm_config_wrapper::set(this, "tb.chan*.rx_agent.sequencer.run_phase",
                            "default_sequence", channel_rx_resp_seq::get_type());
    // c. Clock and Reset sequence
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    // d. Multichannel sequencer drives YAPP and HBUS
    uvm_config_wrapper::set(this, "tb.mcseqr.run_phase",
                            "default_sequence", router_simple_mcseq::get_type());
    // e. Do NOT set default sequence for YAPP or HBUS sequencers
    super.build_phase(phase);
  endfunction : build_phase

endclass : router_mcseq_test

class uvm_mem_walk_test extends base_test;

  uvm_mem_walk_seq mem_walk_seq;

  `uvm_component_utils(uvm_mem_walk_test)

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
    mem_walk_seq = uvm_mem_walk_seq::type_id::create("mem_walk_seq");
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Raising Objection to run uvm mem walk test");
    mem_walk_seq.model = tb.yapp_rm;
    mem_walk_seq.start(null);
    phase.drop_objection(this, "Dropping Objection after uvm mem walk test finished");
  endtask

endclass : uvm_mem_walk_test

class reg_access_test extends base_test;

  yapp_regs_c        regs;
  uvm_status_e       status;
  uvm_reg_data_t     val;

  `uvm_component_utils(reg_access_test)

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    super.build_phase(phase);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Running reg_access_test");
    regs = tb.yapp_rm.router_yapp_regs;

    // --- RW Register Test: en_reg ---
    // 1. Front-door write a unique value
    regs.en_reg.write(status, 8'hA3);
    `uvm_info("reg_access_test", $sformatf("RW write: en_reg = 8'hA3, status=%s", status.name()), UVM_NONE)

    // 2. Peek (backdoor) and check DUT value matches written value
    regs.en_reg.peek(status, val);
    `uvm_info("reg_access_test", $sformatf("RW peek:  en_reg = 8'h%0h", val), UVM_NONE)
    if (val !== 8'hA3)
      `uvm_error("reg_access_test", $sformatf("RW PEEK MISMATCH: expected 8'hA3, got 8'h%0h", val))

    // 3. Poke (backdoor) a new value
    regs.en_reg.poke(status, 8'h55);
    `uvm_info("reg_access_test", "RW poke:  en_reg = 8'h55", UVM_NONE)

    // 4. Front-door read and check it matches poked value
    regs.en_reg.read(status, val);
    `uvm_info("reg_access_test", $sformatf("RW read:  en_reg = 8'h%0h", val), UVM_NONE)
    if (val !== 8'h55)
      `uvm_error("reg_access_test", $sformatf("RW READ MISMATCH: expected 8'h55, got 8'h%0h", val))

    // --- RO Register Test: addr0_cnt_reg ---
    // 1. Poke (backdoor) a unique value
    regs.addr0_cnt_reg.poke(status, 8'hCC);
    `uvm_info("reg_access_test", "RO poke:  addr0_cnt_reg = 8'hCC", UVM_NONE)

    // 2. Front-door read and check it matches poked value
    regs.addr0_cnt_reg.read(status, val);
    `uvm_info("reg_access_test", $sformatf("RO read:  addr0_cnt_reg = 8'h%0h", val), UVM_NONE)
    if (val !== 8'hCC)
      `uvm_error("reg_access_test", $sformatf("RO READ MISMATCH: expected 8'hCC, got 8'h%0h", val))

    // 3. Front-door write a new value (hardware should ignore for RO)
    regs.addr0_cnt_reg.write(status, 8'hFF);
    `uvm_info("reg_access_test", "RO write: addr0_cnt_reg = 8'hFF (should be ignored by DUT)", UVM_NONE)

    // 4. Peek (backdoor) and verify DUT value has NOT changed
    regs.addr0_cnt_reg.peek(status, val);
    `uvm_info("reg_access_test", $sformatf("RO peek:  addr0_cnt_reg = 8'h%0h (should still be 8'hCC)", val), UVM_NONE)
    if (val !== 8'hCC)
      `uvm_error("reg_access_test", $sformatf("RO PEEK MISMATCH: expected 8'hCC (unchanged), got 8'h%0h", val))

    phase.drop_objection(this, "reg_access_test done");
  endtask

endclass : reg_access_test

class reg_function_test extends base_test;

  yapp_regs_c       regs;
  yapp_tx_sequencer yapp_seqr;
  yapp_012_seq      yapp_seq;
  uvm_status_e      status;
  uvm_reg_data_t    val;

  `uvm_component_utils(reg_function_test)

  virtual function bit use_default_sequence();
    return 0;
  endfunction : use_default_sequence

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    uvm_reg::include_coverage("*", UVM_NO_COVERAGE);
    yapp_seq = yapp_012_seq::type_id::create("yapp_seq");
    uvm_config_wrapper::set(this, "tb.clock_and_reset.agent.sequencer.run_phase",
                            "default_sequence", clk10_rst5_seq::get_type());
    uvm_config_wrapper::set(this, "tb.chan*.rx_agent.sequencer.run_phase",
                            "default_sequence", channel_rx_resp_seq::get_type());
    super.build_phase(phase);
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    yapp_seqr = tb.yapp.tx_agent.sequencer;
  endfunction : connect_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Running reg_function_test");
    regs = tb.yapp_rm.router_yapp_regs;

    // Step 7: Enable automatic checking of read values against model mirror
    tb.yapp_rm.default_map.set_check_on_read(1);

    // 1. Write only router enable bit in en_reg
    regs.en_reg.write(status, 8'h01);
    `uvm_info("reg_function_test", $sformatf("Write en_reg=8'h01 (router_en only), status=%s", status.name()), UVM_NONE)

    // 2. Read en_reg to verify
    regs.en_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("Read  en_reg=8'h%0h (expect 8'h01)", val), UVM_NONE)
    if (val !== 8'h01)
      `uvm_error("reg_function_test", $sformatf("en_reg mismatch: expected 8'h01, got 8'h%0h", val))

    // 3. Execute yapp_012_seq (addr count enables are OFF)
    `uvm_info("reg_function_test", "Execute yapp_012_seq #1 (addr cnt disabled)", UVM_NONE)
    yapp_seq.start(yapp_seqr);

    // 4. Check all addr counters NOT incremented (enables were off)
    regs.addr0_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr0_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("addr0_cnt_reg should be 0, got 8'h%0h", val))

    regs.addr1_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr1_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("addr1_cnt_reg should be 0, got 8'h%0h", val))

    regs.addr2_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr2_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("addr2_cnt_reg should be 0, got 8'h%0h", val))

    regs.addr3_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr3_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("addr3_cnt_reg should be 0, got 8'h%0h", val))

    // 5. Set all enable bits
    regs.en_reg.write(status, 8'hff);
    `uvm_info("reg_function_test", $sformatf("Write en_reg=8'hff (all enables ON), status=%s", status.name()), UVM_NONE)

    // 6. Execute yapp_012_seq TWICE (all enables ON)
    `uvm_info("reg_function_test", "Execute yapp_012_seq #2 and #3 (addr cnt enabled)", UVM_NONE)
    yapp_seq.start(yapp_seqr);
    yapp_seq.start(yapp_seqr);

    // Step 9: predict expected values before read (for check_on_read)
    // addr0/1/2 each received 2 packets; addr3 received 0
    void'(regs.addr0_cnt_reg.predict(8'h02));
    void'(regs.addr1_cnt_reg.predict(8'h02));
    void'(regs.addr2_cnt_reg.predict(8'h02));

    // 7. Check addr counters incremented: addr0/1/2 = 2, addr3 = 0
    regs.addr0_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr0_cnt_reg=8'h%0h (expect 2)", val), UVM_NONE)
    if (val !== 8'h02)
      `uvm_error("reg_function_test", $sformatf("addr0_cnt_reg should be 2, got 8'h%0h", val))

    regs.addr1_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr1_cnt_reg=8'h%0h (expect 2)", val), UVM_NONE)
    if (val !== 8'h02)
      `uvm_error("reg_function_test", $sformatf("addr1_cnt_reg should be 2, got 8'h%0h", val))

    regs.addr2_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr2_cnt_reg=8'h%0h (expect 2)", val), UVM_NONE)
    if (val !== 8'h02)
      `uvm_error("reg_function_test", $sformatf("addr2_cnt_reg should be 2, got 8'h%0h", val))

    regs.addr3_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("addr3_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("addr3_cnt_reg should be 0, got 8'h%0h", val))

    // 8. Read parity error and oversized packet counters
    // parity_err_cnt may be non-zero (random); peek first to get DUT value, then predict
    regs.parity_err_cnt_reg.peek(status, val);
    void'(regs.parity_err_cnt_reg.predict(val));
    regs.parity_err_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("parity_err_cnt_reg=8'h%0h", val), UVM_NONE)

    // oversized_pkt_cnt_reg should be 0
    void'(regs.oversized_pkt_cnt_reg.predict(8'h00));
    regs.oversized_pkt_cnt_reg.read(status, val);
    `uvm_info("reg_function_test", $sformatf("oversized_pkt_cnt_reg=8'h%0h (expect 0)", val), UVM_NONE)
    if (val !== 8'h00)
      `uvm_error("reg_function_test", $sformatf("oversized_pkt_cnt_reg should be 0, got 8'h%0h", val))

    // Step 11: Register Introspection - build RW and RO register queues
    begin
      uvm_reg       all_regs[$];
      uvm_reg       rw_regs[$];
      uvm_reg       ro_regs[$];
      uvm_reg       cur_reg;
      uvm_reg_field fields[$];
      string        acc;

      regs.get_registers(all_regs);
      foreach (all_regs[i]) begin
        cur_reg = all_regs[i];
        fields.delete();
        cur_reg.get_fields(fields);
        acc = fields[0].get_access(tb.yapp_rm.default_map);
        if (acc == "RW")
          rw_regs.push_back(cur_reg);
        else if (acc == "RO")
          ro_regs.push_back(cur_reg);
      end

      `uvm_info("introspection", $sformatf("RW registers (%0d):", rw_regs.size()), UVM_NONE)
      foreach (rw_regs[i])
        `uvm_info("introspection", $sformatf("  %s", rw_regs[i].get_name()), UVM_NONE)

      `uvm_info("introspection", $sformatf("RO registers (%0d):", ro_regs.size()), UVM_NONE)
      foreach (ro_regs[i])
        `uvm_info("introspection", $sformatf("  %s", ro_regs[i].get_name()), UVM_NONE)
    end

    phase.drop_objection(this, "reg_function_test done");
  endtask

endclass : reg_function_test
