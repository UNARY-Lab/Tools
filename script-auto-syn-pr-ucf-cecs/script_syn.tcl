# ECE552 Extra Credit
read_file -format verilog {dut.v}
set current_design dut
set clk_name iClk
set rstn_name iRstN
link

###########################################
# Define clock and set don't mess with it #
###########################################
# clk with frequency of 400 MHz
create_clock -name $clk_name -period 2.5 -waveform { 0 1.25 } { $clk_name }
set_false_path -from [get_ports $rstn_name]
set compile_delete_unloaded_sequential_cells false
set compile_seqmap_propagate_constants false
set_dont_touch_network [find port $clk_name]
# pointer to all inputs except $clk_name
set prim_inputs [remove_from_collection [all_inputs] [find port $clk_name]]
# pointer to all inputs except $clk_name and $rstn_name
set prim_inputs_no_rst [remove_from_collection $prim_inputs [find port $rstn_name]]
# Set clk uncertainty (skew)
set_clock_uncertainty 0.15 $clk_name

#########################################
# Set input delay & drive on all inputs #
#########################################
set_input_delay -clock $clk_name 0.25 [copy_collection $prim_inputs]
#set_driving_cell -lib_cell ND2D2BWP -library tcbn40lpbwptc $prim_inputs_no_rst
# rst goes to many places so don't touch
set_dont_touch_network [find port $rstn_name]

##########################################
# Set output delay & load on all outputs #
##########################################
set_output_delay -clock $clk_name 0.5 [all_outputs]
set_load 0.1 [all_outputs]

#############################################################
# Wire load model allows it to estimate internal parasitics #
#############################################################
# set_wire_load_model -name TSMC32K_Lowk_Conservative -library tcbn40lpbwptc

######################################################
# Max transition time is important for Hot-E reasons #
######################################################
set_max_transition 0.1 [current_design]

########################################
# Now actually synthesize for 1st time #
########################################
compile -map_effort medium
check_design

# Unflatten design now that its compiled
set_flatten true
uniquify -force
ungroup -all -flatten
# force hold time to be met for all flops
set_fix_hold $clk_name

# Compile again with higher effort
compile -map_effort high
check_design

#############################################
# Take a look at area, max, and min timings #
#############################################
report_area > dut_area.syn.txt
report_power > dut_power.syn.txt
report_timing -delay min > dut_min_delay.syn.txt
report_timing -delay max > dut_max_delay.syn.txt

#### write out final netlist ######
write -format verilog -output dut.syn.vg
#### write out sdc ######
write_sdc dut.syn.sdc
exit
