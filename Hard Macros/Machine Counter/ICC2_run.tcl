
####### library creation #############
create_lib -technology ../../../dc_compiler/ref/tech/saed32nm_1p9m.tf -ref_libs  \
{../../../dc_compiler/ref/CLIBs/saed32_1p9m_tech.ndm ../../../dc_compiler/ref/CLIBs/saed32_hvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_lvt.ndm ../../../dc_compiler/ref/CLIBs/saed32_rvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_sram_lp.ndm} machine_counter

############ reading netlist and SDC ##########
read_verilog ../extracted_files/machine_counter.v
read_sdc ../extracted_files/mc.sdc

######### floor plan ##############
link_design
initialize_floorplan -core_offset {4} -core_utilization 0.7 -side_ratio {3 3}

######### parasitic reading #########
read_parasitic_tech -name {new_model} -tlup {../../../dc_compiler/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus} -layermap  \
{../../../dc_compiler/ref/tech/saed32nm_tf_itf_tluplus.map}

########## MCMM #########
current_corner default
set_parasitic_parameters -early_spec new_model -late_spec new_model
set_process_number 0.99 -corners default
set_temperature 125 -corners default
set_voltage 0.75 -corners default
current_mode default
set_scenario_status default -active true -setup true -hold true -max_transition true -max_capacitance true -min_capacitance true -leakage_power true  \
-dynamic_power true

#missing scandef
set_app_options -list {place.coarse.continue_on_missing_scandef {true}}

######### Tie-cell insertion #########
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

########## power planning ############
source -echo ./pns.tcl
check_pg_connectivity 
check_pg_drc

########## placement ###########
set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
create_placement -floorplan
legalize_placement
#place_pins -self

######## manual pin placement ########
set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 1
place_pins -ports [get_ports -filter direction==in]

set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 3
place_pins -ports [get_ports -filter direction==out]

set_attribute [get_ports *] physical_status fixed


######### CTS Stage ##########
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
report_clock_settings
report_qor -summary
clock_opt

##########routing##########
#set_routing_rule all -clear -default_rule -min_routing_layer 1 -max_routing_layer 9
set_app_options -name route.common.verbose_level -value 1
check_design -checks pre_route_stage

set_app_options -name route.track.timing_driven     -value true
set_app_options -name route.track.crosstalk_driven  -value true
set_app_options -name route.detail.timing_driven    -value true
route_auto -max_detail_route_iterations 15
route_opt
route_eco
#signoff_check_drc -auto_eco true

######## reports ###########
report_constraints -all_violators
check_legality > ../reports/legality.rpt
check_lvs > ../reports/lvs.rpt
report_timing > ../reports/timing_report.rpt
report_global_timing > ../reports/global_timing_report.rpt
report_congestion > ../reports/congestion.rpt

########## script writing ###########
write_script -force -format icc2 -output ../reports/mc_spef
write_parasitics -output ../reports/spef_generation_1
write_sdf ../results/machine_counter.sdf
write_verilog ../results/machine_counter.v
write_sdc -output ../results/machine_counter.sdc
create_abstract
create_frame -block_all true
write_gds -compress -hierarchy all -long_names -keep_data_type ../results/machine_counter.gds

save_block

puts "Finished"
