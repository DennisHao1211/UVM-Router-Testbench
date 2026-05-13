// 64 bit option for AWS labs
-64

-uvmhome $UVMHOME

// include directories
-incdir .
-incdir ../sv
-incdir ../../yapp/sv
-incdir ../../channel/sv
-incdir ../../hbus/sv
-incdir ../../clock_and_reset/sv

// options
+UVM_VERBOSITY=UVM_LOW
+UVM_TESTNAME=reg_function_test
+SVSEED=random

// default timescale
-timescale 1ns/1ns

// compile files

// YAPP UVC
../../yapp/sv/yapp_pkg.sv
../../yapp/sv/yapp_if.sv

// Channel UVC
../../channel/sv/channel_pkg.sv
../../channel/sv/channel_if.sv

// HBUS UVC
../../hbus/sv/hbus_pkg.sv
../../hbus/sv/hbus_if.sv

// Clock and Reset UVC
../../clock_and_reset/sv/clock_and_reset_pkg.sv
../../clock_and_reset/sv/clock_and_reset_if.sv

// Router Module UVC package (scoreboard + reference + env)
../sv/router_module_pkg.sv

// Register Model files
cdns_uvmreg_utils_pkg.sv
yapp_router_regs_rdb.sv

// TB files
clkgen.sv
tb_top.sv
hw_top.sv
../../router_rtl/yapp_router.sv
