# Developed by M Sazadur Rahman
# PhD Candidate: University of Florida
# Please contact mohammad.rahman@ufl.edu for any quries.
# in terminal:
# source /apps/settings
# icc2_shell -gui

##need to be modified
set workpath [format "%s%s" [pwd] "/"]
set design_path [format "%s%s" [pwd] "/"]
set design_name dut

global design_name
global design_path

set design_file [format "%s%s" $design_name ".syn.vg"]
set sdc_file [format "%s%s" $design_name ".syn.sdc"]
set lib_path "/cae/apps/data/saed32_edk-2018/"

# cd $workpath
############create library
set DESIGN_LIBRARY ${design_name}_LR
set target_library "
/cae/apps/data/saed32_edk-2018/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p75v125c.db
/cae/apps/data/saed32_edk-2018/lib/stdcell_rvt/db_nldm/saed32rvt_ff0p95vn40c.db
/cae/apps/data/saed32_edk-2018/lib/stdcell_rvt/db_nldm/saed32rvt_tt0p85v25c.db
"
set search_path ". /cae/apps/data/saed32_edk-2018/lib/stdcell_rvt/db_nldm/"
set link_library $target_library
create_lib $DESIGN_LIBRARY -technology /cae/apps/data/saed32_edk-2018/tech/milkyway/saed32nm_1p9m_mw.tf
set_ref_libs -library $DESIGN_LIBRARY -ref_libs /cae/apps/data/saed32_edk-2018/lib/stdcell_rvt/lef/saed32nm_rvt_1p9m.lef
#open_lib [format "%s%s" $design_path "demo_icc2"]  
### ADD YOUR DESIGN
read_verilog -top $design_name [format "%s%s" $design_path $design_file]
current_block $design_name
link_block -force ;# -verbose
save_lib
commit_upf
associate_mv_cells -all
reset_design

### Tluplus Files
set TLUPLUS_FILE(Cmax) 	"/cae/apps/data/saed32_edk-2018/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus"
set TLUPLUS_FILE(Cmin) 	"/cae/apps/data/saed32_edk-2018/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus"
set TLUPLUS_FILE(nominal) 	"/cae/apps/data/saed32_edk-2018/tech/star_rcxt/saed32nm_1p9m_nominal.tluplus"
set TLUPLUS_MAP_FILE			"/cae/apps/data/saed32_edk-2018/tech/star_rcxt/saed32nm_tf_itf_tluplus.map"
### SET TIMING AND CAP LIBRARIES
set cornerData {
  {ss0p75v125c  ss  Cmax     0.99 125 0.75}
  {ff0p95vn40c  ff  Cmin     1.01 -40 0.95}
  {tt0p85v25c   tt  nominal  1.00 25 0.85}
}
##############################
## Corners Definition
##############################
foreach corner_data $cornerData {
    set corner_name            [lindex $corner_data 0]
    set corner_process_label   [lindex $corner_data 1]
    set corner_parasitic       [lindex $corner_data 2]
    set corner_process_number  [lindex $corner_data 3]
    set corner_temp            [lindex $corner_data 4]
    set corner_voltage         [lindex $corner_data 5]

    create_corner  $corner_name
    current_corner $corner_name
    
    read_parasitic_tech -tlup $TLUPLUS_FILE($corner_parasitic) -layermap $TLUPLUS_MAP_FILE -name $corner_parasitic
    set_parasitic_parameters -corner $corner_name -library [file tail $DESIGN_LIBRARY] -early_spec $corner_parasitic -late_spec $corner_parasitic
    set_operating_conditions $corner_name 
}                                                                                                                                            
report_corners -verbose

set scenarioData {
   " .*  ss0p75v125c    setup false {{-0.02 capture} { 0.02 launch} { 0.02 data}}"
   " .*  ff0p95vn40c    hold  false {{0.06 capture} { -0.06 launch} { 0.06 data}}"
   " .*  tt0p85v25c     leak  true  {}"
}
set mode func
create_mode $mode
foreach scenario $scenarioData {
   set corner_name    [lindex $scenario 1]
   set check_type     [lindex $scenario 2]
   set power          [lindex $scenario 3]
   set clock_capture       [lindex [lsearch -inline -regexp [join $scenario] " capture$"] 0]
   set clock_launch        [lindex [lsearch -inline -regexp [join $scenario] " launch$" ] 0]
   set data                [lindex [lsearch -inline -regexp [join $scenario] " data$"   ] 0]

   set scenario_name ${mode}@${corner_name}.${check_type}
   create_scenario -name $scenario_name -mode $mode -corner $corner_name
   current_scenario $scenario_name
   read_sdc [format "%s%s" $design_path $sdc_file]
   if {$check_type == "setup"} {
    set_timing_derate [expr 1.0 + $clock_capture] -early -clock -cell_delay
    set_timing_derate [expr 1.0 + $data         ] -late  -data  -cell_delay
    set_timing_derate [expr 1.0 + $clock_launch]  -late  -clock -cell_delay
    set_scenario_status $scenario_name -none -setup true  -hold false -leakage_power $power -dynamic_power $power -max_transition true  -max_capacitance true  -min_capacitance false -active true
   }
   if {$check_type == "hold"} { 
    set_timing_derate [expr 1.0 + $clock_capture] -late  -clock -cell_delay
    set_timing_derate [expr 1.0 + $data         ] -early -data  -cell_delay
    set_timing_derate [expr 1.0 + $clock_launch]  -early -clock -cell_delay
    set_scenario_status $scenario_name -none -setup false -hold true -leakage_power $power -dynamic_power $power -max_transition false  -max_capacitance false  -min_capacitance true -active true
   }
   if {$check_type == "leak"} {
    set_scenario_status $scenario_name -none -setup true -hold true -leakage_power $power -dynamic_power $power -max_transition false  -max_capacitance false  -min_capacitance true -active true -signal_em true -cell_em true
   }
}
set_scenario_status -active true [get_scenarios]
### Additional constraints
set_app_options -name time.enable_clock_to_data_analysis -value true
set_app_options -name time.enable_io_path_groups -value true
foreach_in_collection mode [all_modes] {
   current_mode $mode
   remove_propagated_clocks [all_clocks]
   remove_propagated_clocks [get_ports]
   remove_propagated_clocks [get_pins -hierarchical]
}
set LIMIT_SLEW(DATA)    "0.200"
set LIMIT_SLEW(CLOCK)   "0.080"
set LIMIT_FANOUT(CLOCK)   "60"
set LIMIT_CAP(CLOCK)    "0.150" ;# Check unit settings 1.00pF

set_max_transition $::LIMIT_SLEW(DATA) [current_design]
## define limits on all modes for data nets and for clock nets
foreach mode [get_object_name [all_modes]] {
    current_mode $mode
    set_max_transition $::LIMIT_SLEW(DATA) [current_design] -mode $mode
    set_max_transition -data_path  $LIMIT_SLEW(DATA)  -mode $mode *
    set_max_transition -data_path  $LIMIT_SLEW(DATA)  [get_clocks *] -mode $mode
    set_max_transition -clock_path $LIMIT_SLEW(CLOCK) [get_clocks *] -mode $mode
}

### FLOOR PLAN
initialize_floorplan -shape R -side_ratio 1.0 -core_utilization 0.60 -core_offset {5 5 5 5}
## Power RAIL
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_pg_regions -all
remove_pg_patterns -all
remove_pg_strategies -all

create_net -power VDD
create_net -ground VSS
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]
create_pg_std_cell_conn_pattern rail_pat_m1 -layers M1 -rail_width 0.096
set_pg_strategy rail_strat_m1 -core -pattern  { {name: rail_pat_m1} {nets: VDD VSS} }
set_pg_strategy_via_rule rail_rule_m1 -via_rule { {{intersection: undefined} {via_master: nil}} }
compile_pg -strategies rail_strat_m1 -via_rule rail_rule_m1
### POWER RINGS
create_pg_ring_pattern ring_pat -horizontal_layer {M9} -horizontal_width 0.16 -horizontal_spacing 0.16 -vertical_layer M8 -vertical_width 0.16 -vertical_spacing 0.16
set_pg_strategy ring_strat -core -pattern {{name: ring_pat} {nets: {VDD VSS}} {offset: {3 3}}  {parameters: {M9 10 2 M8 10 2 true}}} -extension {{stop: design_boundary}}
set_pg_strategy_via_rule ring_strat_via -via_rule { {{intersection: undefined} {via_master: nil}}}
compile_pg -strategies ring_strat -via_rule ring_strat_via
associate_mv_cells
### Pin placement
set_block_pin_constraints -allowed_layers {M3 M4} -pin_spacing 2 -sides {1 3} -width {0.056} -length {0.4} -self -allow_feedthroughs true
place_pins -self
### PLACE YOUR DESIGN
current_scenario func@ss0p75v125c.setup
set_app_options -name place.coarse.continue_on_missing_scandef -value true
create_bound -name WMBOUND -exclusive -boundary {{0.0 200.0} {50.0 250.0}} [get_cells -of [all_fanout -from [get_ports challenge*] -endpoints_only] -filter "is_sequential == true"]
place_opt
### CTS
current_scenario func@ss0p75v125c.setup
check_clock_tree
report_clock_settings
synthesize_clock_tree -cts_only
report_clock_qor
synthesize_clock_tree -cto_only ;# Balance Tree
report_clock_qor
compute_clock_latency
update_timing -force -full
route_group -all_clock_nets -reuse_existing_global_route true -max_detail_route_iterations 10
synthesize_clock_trees -postroute -routed_clock_stage detail 
report_clock_qor
clock_opt -from build_clock -to route_clock
clock_opt -from final_opto
route_group -all_clock_nets
###Route your design
### global routing
route_opt

### ADD FILLER CELLS
#create_stdcell_fillers -lib_cells "SHFILL128_RVT SHFILL64_RVT SHFILL3_RVT SHFILL2_RVT SHFILL1_RVT"
connect_pg_net

report_power > ${design_name}_power.pr.txt
report_timing -delay min > ${design_name}_min_delay.pr.txt
report_timing -delay max > ${design_name}_max_delay.pr.txt

report_qor > ${design_name}.qor_LR.rpt 
write_verilog ${design_name}.pd_LR.v
write_parasitics  -output ${design_name}.pd_LR.spef
write_sdc -output ${design_name}.pd_LR.sdc
exit
