/*-----------------------------------------------------------------
File name     : yapp_tx_seqs.sv
Developers    : Kathleen Meade, Brian Dickinson
Created       : 01/04/11
Description   : YAPP UVC simple TX test sequence for labs 2 to 4
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

//------------------------------------------------------------------------------
//
// SEQUENCE: base yapp sequence - base sequence with objections from which 
// all sequences can be derived
//
//------------------------------------------------------------------------------
class yapp_base_seq extends uvm_sequence #(yapp_packet);
  
  // Required macro for sequences automation
  `uvm_object_utils(yapp_base_seq)

  // Constructor
  function new(string name="yapp_base_seq");
    super.new(name);
  endfunction

  task pre_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
      // in UVM1.2, get starting phase from method
      phase = get_starting_phase();
    `else
      phase = starting_phase;
    `endif
    if (phase != null) begin
      phase.raise_objection(this, get_type_name());
      `uvm_info(get_type_name(), "raise objection", UVM_MEDIUM)
    end
  endtask : pre_body

  task post_body();
    uvm_phase phase;
    `ifdef UVM_VERSION_1_2
      // in UVM1.2, get starting phase from method
      phase = get_starting_phase();
    `else
      phase = starting_phase;
    `endif
    if (phase != null) begin
      phase.drop_objection(this, get_type_name());
      `uvm_info(get_type_name(), "drop objection", UVM_MEDIUM)
    end
  endtask : post_body

endclass : yapp_base_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_5_packets
//
//  Configuration setting for this sequence
//    - update <path> to be hierarchial path to sequencer 
//
//  uvm_config_wrapper::set(this, "<path>.run_phase",
//                                 "default_sequence",
//                                 yapp_5_packets::get_type());
//
//------------------------------------------------------------------------------
class yapp_5_packets extends yapp_base_seq;
  
  // Required macro for sequences automation
  `uvm_object_utils(yapp_5_packets)

  // Constructor
  function new(string name="yapp_5_packets");
    super.new(name);
  endfunction

  // Sequence body definition
  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_5_packets sequence", UVM_LOW)
     repeat(5)
      `uvm_do(req)
  endtask
  
endclass : yapp_5_packets

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_1_seq
//
//------------------------------------------------------------------------------
class yapp_1_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_1_seq)

  function new(string name="yapp_1_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_1_seq sequence", UVM_LOW)
    `uvm_do_with(req, { addr == 1; })
  endtask

endclass : yapp_1_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_012_seq
//
//------------------------------------------------------------------------------
class yapp_012_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_012_seq)

  function new(string name="yapp_012_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_012_seq sequence", UVM_LOW)
    `uvm_do_with(req, { addr == 0; })
    `uvm_do_with(req, { addr == 1; })
    `uvm_do_with(req, { addr == 2; })
  endtask

endclass : yapp_012_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_111_seq
//
//------------------------------------------------------------------------------
class yapp_111_seq extends yapp_base_seq;

  yapp_1_seq addr_1_seq;

  `uvm_object_utils(yapp_111_seq)

  function new(string name="yapp_111_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_111_seq sequence", UVM_LOW)
    repeat(3)
      `uvm_do(addr_1_seq)
  endtask

endclass : yapp_111_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_repeat_addr_seq
//
//------------------------------------------------------------------------------
class yapp_repeat_addr_seq extends yapp_base_seq;

  rand bit [1:0] prev_addr;

  constraint c_addr { prev_addr != 3; }

  `uvm_object_utils(yapp_repeat_addr_seq)

  function new(string name="yapp_repeat_addr_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_repeat_addr_seq sequence", UVM_LOW)
    `uvm_do_with(req, { addr == local::prev_addr; })
    `uvm_do_with(req, { addr == local::prev_addr; })
  endtask

endclass : yapp_repeat_addr_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_incr_payload_seq
//
//------------------------------------------------------------------------------
class yapp_incr_payload_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_incr_payload_seq)

  function new(string name="yapp_incr_payload_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_incr_payload_seq sequence", UVM_LOW)
    `uvm_create(req)
    assert(req.randomize());
    foreach (req.payload[i])
      req.payload[i] = i;
    req.set_parity();
    `uvm_send(req)
  endtask

endclass : yapp_incr_payload_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_rnd_seq
//
//------------------------------------------------------------------------------
class yapp_rnd_seq extends yapp_base_seq;

  rand int count;

  constraint c_count { count inside {[1:10]}; }

  `uvm_object_utils(yapp_rnd_seq)

  function new(string name="yapp_rnd_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(),
              $sformatf("Executing yapp_rnd_seq sequence, count = %0d", count),
              UVM_LOW)
    repeat(count)
      `uvm_do(req)
  endtask

endclass : yapp_rnd_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: six_yapp_seq
//
//------------------------------------------------------------------------------
class six_yapp_seq extends yapp_base_seq;

  yapp_rnd_seq yapp_rnd;

  `uvm_object_utils(six_yapp_seq)

  function new(string name="six_yapp_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing six_yapp_seq sequence", UVM_LOW)
    `uvm_do_with(yapp_rnd, { count == 6; })
  endtask

endclass : six_yapp_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_exhaustive_seq
//
//------------------------------------------------------------------------------
class yapp_exhaustive_seq extends yapp_base_seq;

  yapp_1_seq            yapp_1;
  yapp_012_seq          yapp_012;
  yapp_111_seq          yapp_111;
  yapp_repeat_addr_seq  yapp_repeat_addr;
  yapp_incr_payload_seq yapp_incr_payload;
  yapp_rnd_seq          yapp_rnd;
  six_yapp_seq          six_yapp;

  `uvm_object_utils(yapp_exhaustive_seq)

  function new(string name="yapp_exhaustive_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_exhaustive_seq sequence", UVM_LOW)
    `uvm_do(yapp_1)
    `uvm_do(yapp_012)
    `uvm_do(yapp_111)
    `uvm_do(yapp_repeat_addr)
    `uvm_do(yapp_incr_payload)
    `uvm_do(yapp_rnd)
    `uvm_do(six_yapp)
  endtask

endclass : yapp_exhaustive_seq

//------------------------------------------------------------------------------
//
// SEQUENCE: yapp_all_channels_seq
// 4 addr (0-3) x 22 lengths (1-22) = 88 packets, 20% bad parity
//
//------------------------------------------------------------------------------
class yapp_all_channels_seq extends yapp_base_seq;

  `uvm_object_utils(yapp_all_channels_seq)

  function new(string name="yapp_all_channels_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing yapp_all_channels_seq (88 packets)", UVM_LOW)
    for (int addr = 0; addr <= 3; addr++) begin
      for (int len = 1; len <= 22; len++) begin
        `uvm_do_with(req, {
          req.addr   == addr;
          req.length == len;
          req.parity_type dist {GOOD_PARITY := 80, BAD_PARITY := 20};
        })
      end
    end
  endtask

endclass : yapp_all_channels_seq
