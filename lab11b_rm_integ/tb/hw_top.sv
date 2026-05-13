/*-----------------------------------------------------------------
File name     : hw_top.sv
Developers    : Kathleen Meade, Brian Dickinson
Created       : 01/04/11
Description   : lab06_vif hardware top module for acceleration
              : Instantiates clock generator, YAPP interface and router DUT
Notes         : From the Cadence "SystemVerilog Accelerated Verification with UVM" training
-------------------------------------------------------------------
Copyright Cadence Design Systems (c)2015
-----------------------------------------------------------------*/

module hw_top;

  // Clock and reset signals
  logic [31:0]  clock_period;
  logic         run_clock;
  logic         clock;
  logic         reset;

  // YAPP Interface to the DUT
  yapp_if in0(clock, reset);

  // Clock and Reset Interface
  clock_and_reset_if cr_if(clock, reset, run_clock, clock_period);

  // HBUS Interface
  hbus_if hbus_if0(clock, reset);

  // Channel Interfaces
  channel_if ch0_if(clock, reset);
  channel_if ch1_if(clock, reset);
  channel_if ch2_if(clock, reset);

  // CLKGEN module generates clock
  clkgen clkgen (
    .clock(clock),
    .run_clock(run_clock),
    .clock_period(clock_period)
  );

  yapp_router dut(
    .reset(reset),
    .clock(clock),
    .error(),

    // YAPP interface
    .in_data(in0.in_data),
    .in_data_vld(in0.in_data_vld),
    .in_suspend(in0.in_suspend),

    // Output Channels
    //Channel 0
    .data_0(ch0_if.data),
    .data_vld_0(ch0_if.data_vld),
    .suspend_0(ch0_if.suspend),
    //Channel 1
    .data_1(ch1_if.data),
    .data_vld_1(ch1_if.data_vld),
    .suspend_1(ch1_if.suspend),
    //Channel 2
    .data_2(ch2_if.data),
    .data_vld_2(ch2_if.data_vld),
    .suspend_2(ch2_if.suspend),

    // HBUS Interface
    .haddr(hbus_if0.haddr),
    .hdata(hbus_if0.hdata_w),
    .hen(hbus_if0.hen),
    .hwr_rd(hbus_if0.hwr_rd));

endmodule
