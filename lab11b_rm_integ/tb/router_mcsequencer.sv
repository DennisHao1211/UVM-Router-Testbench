/*-----------------------------------------------------------------
File name     : router_mcsequencer.sv
Description   : lab08_mcseq multichannel sequencer
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

class router_mcsequencer extends uvm_sequencer;

  `uvm_component_utils(router_mcsequencer)

  // References to sub-sequencers (set by router_tb)
  yapp_tx_sequencer    yapp_seqr;
  hbus_master_sequencer hbus_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : router_mcsequencer
