#######library creation##########
create_lib -technology ../../../dc_compiler/ref/tech/saed32nm_1p9m.tf -ref_libs  \
{../../../dc_compiler/ref/CLIBs/saed32_1p9m_tech.ndm ../../../dc_compiler/ref/CLIBs/saed32_hvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_lvt.ndm ../../../dc_compiler/ref/CLIBs/saed32_rvt.ndm  \
../../../dc_compiler/ref/CLIBs/saed32_sram_lp.ndm   ../../../hard_macro/ref/alu.ndm  \
../../../hard_macro/ref/machine_counter.ndm} risc_v

############reading netlist#############
read_verilog ../../dc/extracted_files/risc_V.v

########## sdc ############
create_clock [get_ports ms_riscv32_mp_clk_in]  -name clk  -period 10
set_clock_uncertainty -setup 0.1 [get_ports ms_riscv32_mp_clk_in]
set_clock_uncertainty -hold 0.01 [get_ports ms_riscv32_mp_clk_in]
#set_clock_latency 3.28 -clock clk [get_pins REG2/iadder_out_reg_out_reg[21]/CLK]
set_output_delay -max 0.0 -clock clk [all_outputs]

###########floor plan##########
link_design
initialize_floorplan -core_offset {4} -core_utilization 0.65 -side_ratio {6 6}

##########create boundary cell#########
#get_lib_cells */DCAP* is used to get the dcap cell name
create_boundary_cells -left_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT -right_boundary_cell saed32_hvt|saed32_hvt_std/DCAP_HVT

#########creating keep out margin#########
create_keepout_margin -type hard -outer {3 3 3 3} [get_flat_cells -filter "is_hard_macro"]

set_attribute [get_cells -physical_context -filter "design_type == macro"] physical_status fixed

##########manual pin placement#########
set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 1
place_pins -ports [get_ports -filter direction==in]

set_block_pin_constraints -self -allowed_layers {M3 M4} -sides 3
place_pins -ports [get_ports -filter direction==out]

set_attribute [get_ports *] physical_status fixed

save_block -as floorplan_done

###########sanity checks##########
check_netlist
report_timing
report_design_mismatch -verbose

##########parasitic reading#########
read_parasitic_tech -name {new_model} -tlup {../../../dc_compiler/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus} -layermap  \
{../../../dc_compiler/ref/tech/saed32nm_tf_itf_tluplus.map}


########### MCMM ##########
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

##########power planning#########
source -echo ../pns.tcl
check_pg_connectivity 
check_pg_drc

##########placement#########
set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
set_app_options -name place_opt.flow.enable_ccd -value true
create_placement -floorplan
#legalize_placement 
place_opt
place_pins -self

save_block -as placement_done

##########CTS Stage#########
set CTS_CELLS [get_lib_cells "*/NBUFF*LVT */NBUFF*RVT */INVX*_LVT */INVX*_RVT */CGL* */LSUP* */*DFF*"]
set_dont_touch $CTS_CELLS false
set_lib_cell_purpose -exclude cts [get_lib_cells] 
set_lib_cell_purpose -include cts $CTS_CELLS
source  ../scripts/cts_include_refs.tcl 
source  ../scripts/ndr.tcl 
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name clock_opt.flow.enable_ccd -value true
#true
report_clock_settings
report_qor -summary
clock_opt

#change_selection [get_pins ]
##########routing#########
report_lib_cells -objects [get_lib_cells *FILL*]
set_attribute [get_lib_cell *FILL*] dont_touch false
source -echo ../scripts/filler.tcl
create_stdcell_fillers -lib_cells $filler_cells -rules {post_route_auto_delete} 
connect_pg_net -automatic
remove_stdcell_fillers_with_violation


#set_routing_rule all -clear -default_rule -min_routing_layer 1 -max_routing_layer 9
set_app_options -list {route.detail.timing_driven {true}}
set_app_options -list {route.track.timing_driven {true}}
set_app_options -list {route_opt.flow.enable_ccd {true}}
route_auto -max_detail_route_iterations 15
route_opt
route_eco

#signoff_check_drc -auto_eco true

######### Reports and Checks #########
check_pg_connectivity > ../reports/pg_connectivity.rpt
check_pg_drc > ../reports/pg_drc.rpt
report_qor -summary > ../reports/qor_summary.rpt
report_design > ../reports/design_report.rpt
report_clock_gating > ../reports/clock_gating_report.rpt
report_constraints -all_violators > ../reports/constraints_report.rpt
report_design_mismatch -verbose
check_routes
check_legality > ../reports/legality.rpt
check_lvs > ../reports/lvs.rpt
report_timing > ../reports/timing_report.rpt
report_global_timing > ../reports/global_timing_report.rpt
report_congestion > ../reports/congestion.rpt
report_design > ../reports/design.rpt

########## Extracting scripts #########
write_script -force -format icc2 -output ../reports/risc_v_spef
write_parasitics -output ../reports/spef_generation_1
write_sdf ../results/risc_v.sdf
write_verilog ../results/risc_v.v
write_gds ../results/risc_v.gds
write_sdc -output ../results/risv_v.sdc

save_block
