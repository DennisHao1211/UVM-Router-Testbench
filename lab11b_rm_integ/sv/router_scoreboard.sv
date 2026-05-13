// Comparison policy: EQUALITY uses != operators, UVM uses uvm_comparer methods
typedef enum bit {EQUALITY, UVM_COMPARE} comp_t;

class router_scoreboard extends uvm_scoreboard;

   // uvm_analysis_imp_decl macros create unique imp class types with different write() suffixes
   // Required when one component needs multiple analysis imp ports
   `uvm_analysis_imp_decl(_yapp)
   `uvm_analysis_imp_decl(_chan0)
   `uvm_analysis_imp_decl(_chan1)
   `uvm_analysis_imp_decl(_chan2)

   // Analysis imp ports: each calls a different write_xxx() method
   uvm_analysis_imp_yapp  #(yapp_packet,    router_scoreboard) sb_yapp_in;
   uvm_analysis_imp_chan0 #(channel_packet, router_scoreboard) sb_chan0;
   uvm_analysis_imp_chan1 #(channel_packet, router_scoreboard) sb_chan1;
   uvm_analysis_imp_chan2 #(channel_packet, router_scoreboard) sb_chan2;

   // One queue per channel address: YAPP packets buffered here until channel confirms delivery
   yapp_packet sb_queue0[$];
   yapp_packet sb_queue1[$];
   yapp_packet sb_queue2[$];

   // Statistics counters
   int packets_in,  in_dropped;
   int packets_ch0, compare_ch0, miscompare_ch0, dropped_ch0;
   int packets_ch1, compare_ch1, miscompare_ch1, dropped_ch1;
   int packets_ch2, compare_ch2, miscompare_ch2, dropped_ch2;

   // Comparison policy: set via config_db or field override
   comp_t compare_policy = EQUALITY;

   `uvm_component_utils_begin(router_scoreboard)
     `uvm_field_enum(comp_t, compare_policy, UVM_ALL_ON)
   `uvm_component_utils_end

   function new(string name="", uvm_component parent=null);
     super.new(name, parent);
     sb_yapp_in = new("sb_yapp_in", this);
     sb_chan0   = new("sb_chan0",   this);
     sb_chan1   = new("sb_chan1",   this);
     sb_chan2   = new("sb_chan2",   this);
   endfunction

   // Custom compare using Verilog equality operators
   // Returns 1 if all fields match, 0 on first mismatch
   function bit comp_equal(input yapp_packet yp, input channel_packet cp);
     if (yp.addr != cp.addr) begin
       `uvm_error("PKT_COMPARE", $sformatf("Address mismatch YAPP %0d Chan %0d", yp.addr, cp.addr))
       return 0;
     end
     if (yp.length != cp.length) begin
       `uvm_error("PKT_COMPARE", $sformatf("Length mismatch YAPP %0d Chan %0d", yp.length, cp.length))
       return 0;
     end
     foreach (yp.payload[i])
       if (yp.payload[i] != cp.payload[i]) begin
         `uvm_error("PKT_COMPARE", $sformatf("Payload[%0d] mismatch YAPP %0d Chan %0d", i, yp.payload[i], cp.payload[i]))
         return 0;
       end
     if (yp.parity != cp.parity) begin
       `uvm_error("PKT_COMPARE", $sformatf("Parity mismatch YAPP %0d Chan %0d", yp.parity, cp.parity))
       return 0;
     end
     return 1;
   endfunction

   // Custom compare using uvm_comparer methods
   // Unlike comp_equal, this checks ALL fields before returning (accumulates mismatches)
   function bit comp_uvm(input yapp_packet yp, input channel_packet cp,
                         uvm_comparer comparer = null);
     string str;
     if (comparer == null) comparer = new();
     comp_uvm  = comparer.compare_field("addr",   yp.addr,   cp.addr,   2);
     comp_uvm &= comparer.compare_field("length", yp.length, cp.length, 6);
     foreach (yp.payload[i]) begin
       str.itoa(i);
       comp_uvm &= comparer.compare_field({"payload[",str,"]"},
                                           yp.payload[i], cp.payload[i], 8);
     end
     comp_uvm &= comparer.compare_field("parity", yp.parity, cp.parity, 8);
   endfunction

   // YAPP write: clone packet (to own its memory) and push to queue by address
   virtual function void write_yapp(yapp_packet packet);
     yapp_packet sb_packet;
     $cast(sb_packet, packet.clone());
     packets_in++;
     case (sb_packet.addr)
       2'b00: begin sb_queue0.push_back(sb_packet);
                    `uvm_info(get_type_name(), "Added packet to Queue 0", UVM_HIGH) end
       2'b01: begin sb_queue1.push_back(sb_packet);
                    `uvm_info(get_type_name(), "Added packet to Queue 1", UVM_HIGH) end
       2'b10: begin sb_queue2.push_back(sb_packet);
                    `uvm_info(get_type_name(), "Added packet to Queue 2", UVM_HIGH) end
       default: begin
                  `uvm_info(get_type_name(),
                    $sformatf("Packet dropped (bad addr=%0d)\n%s", sb_packet.addr, sb_packet.sprint()), UVM_LOW)
                  in_dropped++;
                end
     endcase
   endfunction

   // Channel 0: pop expected packet from queue and compare
   virtual function void write_chan0(channel_packet packet);
     yapp_packet sb_packet;
     packets_ch0++;
     if (sb_queue0.size() == 0) begin
       `uvm_error(get_type_name(),
         $sformatf("Queue0 EMPTY: unexpected Chan0 packet!\n%s", packet.sprint()))
       dropped_ch0++;
       return;
     end
     if ((compare_policy == UVM_COMPARE) ? comp_uvm(sb_queue0[0], packet)
                                         : comp_equal(sb_queue0[0], packet)) begin
       void'(sb_queue0.pop_front());
       `uvm_info(get_type_name(),
         $sformatf("Match: Chan0\n%s", packet.sprint()), UVM_MEDIUM)
       compare_ch0++;
     end else begin
       sb_packet = sb_queue0[0];
       `uvm_warning(get_type_name(),
         $sformatf("MISCOMPARE Chan0\nGot:\n%s\nExpected:\n%s", packet.sprint(), sb_packet.sprint()))
       miscompare_ch0++;
     end
   endfunction

   // Channel 1: pop expected packet from queue and compare
   virtual function void write_chan1(channel_packet packet);
     yapp_packet sb_packet;
     packets_ch1++;
     if (sb_queue1.size() == 0) begin
       `uvm_warning(get_type_name(),
         $sformatf("Queue1 EMPTY: unexpected Chan1 packet!\n%s", packet.sprint()))
       dropped_ch1++;
       return;
     end
     if ((compare_policy == UVM_COMPARE) ? comp_uvm(sb_queue1[0], packet)
                                         : comp_equal(sb_queue1[0], packet)) begin
       void'(sb_queue1.pop_front());
       `uvm_info(get_type_name(),
         $sformatf("Match: Chan1\n%s", packet.sprint()), UVM_MEDIUM)
       compare_ch1++;
     end else begin
       sb_packet = sb_queue1[0];
       `uvm_warning(get_type_name(),
         $sformatf("MISCOMPARE Chan1\nGot:\n%s\nExpected:\n%s", packet.sprint(), sb_packet.sprint()))
       miscompare_ch1++;
     end
   endfunction

   // Channel 2: pop expected packet from queue and compare
   virtual function void write_chan2(channel_packet packet);
     yapp_packet sb_packet;
     packets_ch2++;
     if (sb_queue2.size() == 0) begin
       `uvm_warning(get_type_name(),
         $sformatf("Queue2 EMPTY: unexpected Chan2 packet!\n%s", packet.sprint()))
       dropped_ch2++;
       return;
     end
     if ((compare_policy == UVM_COMPARE) ? comp_uvm(sb_queue2[0], packet)
                                         : comp_equal(sb_queue2[0], packet)) begin
       void'(sb_queue2.pop_front());
       `uvm_info(get_type_name(),
         $sformatf("Match: Chan2\n%s", packet.sprint()), UVM_MEDIUM)
       compare_ch2++;
     end else begin
       sb_packet = sb_queue2[0];
       `uvm_warning(get_type_name(),
         $sformatf("MISCOMPARE Chan2\nGot:\n%s\nExpected:\n%s", packet.sprint(), sb_packet.sprint()))
       miscompare_ch2++;
     end
   endfunction

   // check_phase runs after run_phase: all queues should be empty if every sent packet was received
   function void check_phase(uvm_phase phase);
     `uvm_info(get_type_name(), "Checking Router Scoreboard", UVM_LOW)
     if (sb_queue0.size() || sb_queue1.size() || sb_queue2.size())
       `uvm_error(get_type_name(),
         $sformatf("Queues NOT empty: Chan0=%0d  Chan1=%0d  Chan2=%0d",
           sb_queue0.size(), sb_queue1.size(), sb_queue2.size()))
     else
       `uvm_info(get_type_name(), "All queues empty - OK", UVM_LOW)
   endfunction : check_phase

   function void report_phase(uvm_phase phase);
     `uvm_info(get_type_name(), $sformatf(
       "\n   Scoreboard Statistics\n     Pkts In: %0d  Dropped: %0d\n     Chan0: total=%0d pass=%0d mismatch=%0d dropped=%0d\n     Chan1: total=%0d pass=%0d mismatch=%0d dropped=%0d\n     Chan2: total=%0d pass=%0d mismatch=%0d dropped=%0d",
       packets_in, in_dropped,
       packets_ch0, compare_ch0, miscompare_ch0, dropped_ch0,
       packets_ch1, compare_ch1, miscompare_ch1, dropped_ch1,
       packets_ch2, compare_ch2, miscompare_ch2, dropped_ch2), UVM_LOW)
     if ((miscompare_ch0 + miscompare_ch1 + miscompare_ch2 +
          dropped_ch0    + dropped_ch1    + dropped_ch2) > 0)
       `uvm_error(get_type_name(), "Status: Simulation FAILED")
     else
       `uvm_info(get_type_name(), "Status: Simulation PASSED", UVM_NONE)
   endfunction : report_phase

endclass : router_scoreboard
