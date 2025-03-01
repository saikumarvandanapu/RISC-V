#library creation
create_lib -technology ../../../dc_compiler/ref/tech/saed32nm_1p9m.tf -ref_libs  \
{../../../dc_compiler/ref/CLIBs/saed32_1p9m_tech.ndm ../../../dc_compiler/ref/CLIBs/saed32_hvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_lvt.ndm ../../../dc_compiler/ref/CLIBs/saed32_rvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_sram_lp.ndm   ../../../hard_macro/ref/alu.ndm  \
../../../hard_macro/ref/machine_counter.ndm} risc_v

#reading netlist and SDC
read_verilog ../../dc/extracted_files/risc_V.v
read_sdc ../../dc/extracted_files/risc_V.sdc

#floor plan
link_design
initialize_floorplan -core_offset {4} -core_utilization 0.7 -side_ratio {5 5}

#sanity checks
check_netlist
report_timing
report_design_mismatch -verbose

#parasitic reading
read_parasitic_tech -name {new_model} -tlup {../../../dc_compiler/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus} -layermap  \
{../../../dc_compiler/ref/tech/saed32nm_tf_itf_tluplus.map}

#setting routing layers
get_site_defs
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction vertical


#MCMM
current_corner default
set_parasitic_parameters -early_spec new_model -late_spec new_model
set_process_number 0.99 -corners default
set_temperature 125 -corners default
set_voltage 0.75 -corners default
current_mode default
set_scenario_status default -active true -setup true -hold true -max_transition true -max_capacitance true -min_capacitance true -leakage_power true  \
-dynamic_power true

######### Tie-cell insertion #########
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

#power planning
source -echo ../pns1.tcl
check_pg_connectivity 
check_pg_drc

#create boundary cell
#get_lib_cells */DCAP* is used to get the dcap cell name
create_boundary_cells -left_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT -right_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT

#creating keep out margin
create_keepout_margin -type hard -outer {3 3 3 3} [get_flat_cells -filter "is_hard_macro"]
#set_attribute [get_cells -physical_context -filter "design_type == macro"] physical_status fixed

#placement
set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
create_placement -floorplan
get_app_option_value -name place_opt.flow.enable_ccd
place_opt
place_pins -self

#manual pin placement
set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 1
place_pins -ports [get_ports -filter direction==in]

set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 3
place_pins -ports [get_ports -filter direction==out]

set_attribute [get_ports *] physical_status fixed

save_block -as floorplan_done

#CTS Stage
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name clock_opt.flow.enable_ccd -value true
#true
set_app_options -name cts.compile.enable_local_skew -value false
#false
set_app_options -name cts.optimize.enable_local_skew -value false
#false
report_clock_settings
report_qor -summary
clock_opt

#routing
#set_routing_rule all -clear -default_rule -min_routing_layer 1 -max_routing_layer 9
set_app_options -name route.track.timing_driven     -value false
#false
set_app_options -name route.track.crosstalk_driven  -value false
#false
set_app_options -name route.detail.timing_driven    -value false
#false
route_auto -max_detail_route_iterations 15
route_opt
route_eco

#signoff_check_drc -auto_eco true
check_pg_connectivity 
check_pg_drc
report_constraints -all_violators
report_design_mismatch -verbose
check_routes
check_legality > ../reports/legality.rpt
check_lvs > ../reports/lvs.rpt
report_timing > ../reports/timing_report.rpt
report_global_timing > ../reports/global_timing_report.rpt
report_congestion > ../reports/congestion.rpt

#script writing
write_script -force -format icc2 -output ../reports/risc_v_spef
write_parasitics -output ../reports/spef_generation_1
write_sdf ../results/risc_v.sdf
write_verilog ../results/risc_v.v
write_gds ../results/risc_v.gds
write_sdc -output ../results/risv_v.sdc

save_block