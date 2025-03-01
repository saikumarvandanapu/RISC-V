#####################################################################
####connecting pg nets####
#####################################################################

remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect > /dev/null

set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

connect_pg_net -automatic

create_pg_ring_pattern ring1 \
            -horizontal_layer M8 -vertical_layer M7 \
            -horizontal_width 1 -vertical_width 1 \
            -horizontal_spacing 1 -vertical_spacing 1 
set_pg_strategy ring_str -core -pattern {{pattern: ring1}{nets: {VDD VSS}}} -blockage {macros: all}
compile_pg -strategies {ring_str} -drc no_check

#####################################################################
####creating pg mesh pattern#####
#####################################################################
create_pg_mesh_pattern mesh_pattern -layers { {{vertical_layer: M7} {width: 0.26} {pitch: 4.5} {spacing: interleaving}}  {{horizontal_layer: M8} {width: 0.35} {pitch:6} {spacing: interleaving}} }
set_pg_strategy mesh_strategy -core -pattern {{pattern: mesh_pattern}{nets: {VDD VSS}}} -blockage {macros: all} -extension {stop: outermost_ring}
compile_pg -strategies {mesh_strategy} -drc no_check

#####################################################################
####creating PG Rails####
#####################################################################
create_pg_std_cell_conn_pattern std_cell_pattern 
set_pg_strategy std_cell_strategy -core -pattern {{pattern: std_cell_pattern}{nets: {VDD VSS}}}
compile_pg -strategies {std_cell_strategy} -drc no_check
check_pg_connectivity
check_pg_drc
