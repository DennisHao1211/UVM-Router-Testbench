/*-----------------------------------------------------------------
File name     : router_mcseqs_lib.sv
Description   : lab08_mcseq multichannel sequence library
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

class router_simple_mcseq extends uvm_sequence;

  `uvm_object_utils(router_simple_mcseq)
  `uvm_declare_p_sequencer(router_mcsequencer)

  hbus_small_packet_seq     small_pkt_seq;
  hbus_read_max_pkt_seq     read_max_seq;
  yapp_012_seq              yapp_012;
  hbus_set_default_regs_seq large_pkt_seq;
  six_yapp_seq              six_yapp;

  function new(string name="router_simple_mcseq");
    super.new(name);
  endfunction : new

  virtual task body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
      phase = get_starting_phase();
    `else
      phase = starting_phase;
    `endif

    // Raise objection to keep simulation alive
    if (phase != null) begin
      phase.raise_objection(this, get_type_name());
      `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
    end

    // Set router to accept small packets (maxpktsize=20, router_en=1)
    `uvm_do_on(small_pkt_seq, p_sequencer.hbus_seqr)

    // Read MAXPKTSIZE register to verify
    `uvm_do_on(read_max_seq, p_sequencer.hbus_seqr)

    // Send 6 YAPP packets to addresses 0, 1, 2 (yapp_012_seq x2)
    `uvm_do_on(yapp_012, p_sequencer.yapp_seqr)
    `uvm_do_on(yapp_012, p_sequencer.yapp_seqr)

    // Set router to accept large packets (maxpktsize=63, router_en=1)
    `uvm_do_on(large_pkt_seq, p_sequencer.hbus_seqr)

    // Read MAXPKTSIZE register to verify
    `uvm_do_on(read_max_seq, p_sequencer.hbus_seqr)

    // Send a random sequence of six YAPP packets
    `uvm_do_on(six_yapp, p_sequencer.yapp_seqr)

    // Drop objection to allow simulation to end
    if (phase != null) begin
      phase.drop_objection(this, get_type_name());
      `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
    end

  endtask : body

endclass : router_simple_mcseq
