
########setting up technology and milky way library######

set tech_file  {../../../dc_compiler/ref/tech/saed32nm_1p9m.tf}
set synthetic_library dw_foundation.sldb
#set mw_path "../../../dc_compiler/libs/mw_libs"
set mw_ref_libs "../../../dc_compiler/libs/mw_libs/saed32_io_fc ../../../dc_compiler/libs/mw_libs/saed32nm_lvt_1p9m"
set my_mw_lib mc_mw_lib.mw

#######creating library to save files############
create_mw_lib $my_mw_lib \
         -technology $tech_file \
         -mw_reference_library $mw_ref_libs \
         -open
           
#######linking the libraries###############  
set target_library  {\
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32rvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32hvt_ss0p75v125c.db \
../../../dc_compiler/ref/DBs/saed32sramlp_ss0p95v125c_i0p95v.db}

set link_library  {\
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32rvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32hvt_ss0p75v125c.db \
../../../dc_compiler/ref/DBs/saed32sramlp_ss0p95v125c_i0p95v.db}

set ref_libs   {\
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32lvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32rvt_ss0p95v125c.db \
../../../dc_compiler/ref/DBs/saed32hvt_ss0p75v125c.db \
../../../dc_compiler/ref/DBs/saed32sramlp_ss0p95v125c_i0p95v.db}  
 
########### Reading TLU PLUS libraries ################
set_tlu_plus_files\
   		-max_tluplus ../../../dc_compiler/ref/tech/saed32nm_1p9m_Cmax.lv.tluplus \
     		-min_tluplus ../../../dc_compiler/ref/tech/saed32nm_1p9m_Cmin.lv.tluplus \

       		
############ Reading Verilog file ############
#read_verilog  /home1/BPD23/VandanapuSK/VLSI_PD/Major_project/dc_compiler/rtl/*.v
read_verilog [glob ../machine_counter.v]
current_design machine_counter

######## source the floorplan.pcon file #############
source ./floorplan_constraints.pcon

######### reading sdc constraints #######
create_clock -period 10 -name clk [get_ports clk_in]

#set_wire_load_model -name wire_load.tcl
set_svf mc.svf
# dft constraints
#set_dft_signal -view existing_dft -type ScanClock -port router_clock -timing [list 45 55]
#set_dft_signal -view existing_dft -type Reset -port router_clock -active_state 1
#set_scan_configuration -chain_count 4
#create_test_protocol
#dft_drc
#preview_dft
#insert_dft

########## compile ultra ###########
compile_ultra -no_autoungroup -no_boundary_optimization
write_icc2_files -output ../extracted_files/mc  -force

########## writing scripts ###########
write -hierarchy -format ddc -output ../extracted_files/mc.ddc 
report_area > ../reports/mc_area.rpt
report_hierarchy > ../reports/mc_hierarchy.rpt
report_design > ../reports/mc_design.rpt
report_timing -path full > ../reports/mc_timing.rpt
write -hierarchy -format verilog -output ../extracted_files/machine_counter.v
write_sdf  ../extracted_files/mc.sdf
write_parasitics -output ../extracted_files/mc_parastics_8_6
write_sdc ../extracted_files/mc.sdc 
write -format ddc -h -o ../extracted_files/mc.ddc 

puts "Finished"
#exit
