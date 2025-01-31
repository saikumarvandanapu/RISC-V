create_workspace -technology ../../../dc_compiler/ref/tech/saed32nm_1p9m.tf -flow normal alu.ndm
read_gds ../results/machine_counter.gds

#checks the integrity of the workspace, possibly ensuring that all the necessary and configuration are properly loaded
check_workspace
set_attribute [get_lib_cells alu] design_type macro

#saves or commits the current state of the workspace into an output fiel
commit_workspace -output machine_counter.ndm

