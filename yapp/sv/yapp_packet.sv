/*-----------------------------------------------------------------
File name     : yapp_packet.sv
Description   : lab01_data YAPP UVC packet template file
Notes         : From the Cadence "SystemVerilog Advanced Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

// Define your enumerated type(s) here
typedef enum bit {BAD_PARITY, GOOD_PARITY} parity_t;

class yapp_packet extends uvm_sequence_item;

// Follow the lab instructions to create the packet.
// Place the packet declarations in the following order:

  // Define protocol data
  rand bit [5:0]    length;
  rand bit [1:0]    addr;
  rand bit [7:0]    payload [ ];
  bit      [7:0]    parity;

  // Define control knobs
  rand parity_t parity_type;
  rand int packet_delay;

  // Enable automation of the packet's fields
    //------------------------------------------------------------------
  // UVM macros for built-in automation
  //------------------------------------------------------------------
  `uvm_object_utils_begin(yapp_packet)
    `uvm_field_int   (length,       UVM_ALL_ON)
    `uvm_field_int   (addr,         UVM_ALL_ON)
    `uvm_field_array_int(payload,   UVM_ALL_ON)
    `uvm_field_int   (parity,       UVM_ALL_ON)
    `uvm_field_enum  (parity_t, parity_type, UVM_ALL_ON)
    `uvm_field_int   (packet_delay, UVM_ALL_ON | UVM_DEC | UVM_NOCOMPARE)
  `uvm_object_utils_end

  //------------------------------------------------------------------
  // Constructor
  //------------------------------------------------------------------
  function new(string name="yapp_packet");
    super.new(name);
  endfunction : new

  // ---------------- Constraints ----------------
  // payload size must match length
  constraint c_payload_size { length == payload.size(); }

  // legal length range
  constraint c_length       { length > 0; length < 64; }

  // delay between 0 and 19
  constraint c_delay        { packet_delay >= 0; packet_delay < 20; }

  // mostly GOOD parity, 5:1 ratio
  constraint c_parity_type  { parity_type dist { BAD_PARITY := 1,
                                                 GOOD_PARITY := 5 }; }

  // valid addresses 0,1,2
  constraint c_addr         { addr inside {0,1,2}; }

  // ---------------- Helper methods ----------------
  // Calculate correct parity over header + payload
  function bit [7:0] calc_parity();
    bit [7:0] p;
    p = {length, addr};
    foreach (payload[i]) begin
      p ^= payload[i];
    end
    return p;
  endfunction

  // Set parity according to parity_type knob
  function void set_parity();
    bit [7:0] good_p = calc_parity();
    if (parity_type == BAD_PARITY)
      parity = ~good_p;     // intentionally wrong
    else
      parity = good_p;      // correct parity
  endfunction

  // post_randomize hook
  function void post_randomize();
    set_parity();
  endfunction

endclass: yapp_packet

class short_yapp_packet extends yapp_packet;

  `uvm_object_utils(short_yapp_packet)

  function new(string name="short_yapp_packet");
    super.new(name);
  endfunction : new

  constraint c_short_length { length < 15; }
  // constraint c_not_addr_2   { addr != 2; }

endclass : short_yapp_packet
