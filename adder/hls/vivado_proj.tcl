# Script to add the required files and create the BD.
# This is meant for the adder demo, but can be adapted for other designs.
# The main difficulty will be in changing the AXI port mappings.
# Note: this script will fail if the project already exists
#       so ideally delete ../build before running this and the VHLS script

set build_dir "../build/vivado"

# Set the project name
set _xil_proj_name_ "add_pynq"

# Create project - force overwrite if it exists
create_project -force \
  ${_xil_proj_name_} \
  $build_dir/${_xil_proj_name_} \
  -part xc7z020clg400-1

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" \
  -value "$proj_dir/${_xil_proj_name_}.cache/ip" \
  -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value "xc7z020clg400-1" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" \
  -value "$proj_dir/${_xil_proj_name_}.ip_user_files" \
  -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# File and repository path setup
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$build_dir/../vhls"]" $obj
update_ip_catalog -rebuild
# Currently adding a constraint set without any constraints
# Not needed for pure Pynq designs
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

set_property -name "top" -value "pynq_wrapper" -objects $obj

# Proc to create BD pynq
proc cr_bd_pynq { parentCell } {
  set design_name pynq
  create_bd_design $design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }
  set parentObj [get_bd_cells $parentCell]
  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
  # Set parent object as current
  current_bd_instance $parentObj

  # DDR and FIXED_IO are standard Zynq interfaces.  Just leave them there.
  # Create interface ports
  set DDR [ create_bd_intf_port \
    -mode Master \
    -vlnv xilinx.com:interface:ddrx_rtl:1.0 \
    DDR ]

  set FIXED_IO [ create_bd_intf_port \
    -mode Master \
    -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 \
    FIXED_IO ]


  # Create ports

  ###### This is the custom instance we are adding!!!! ########
  # Ensure that the Vendor-Library-Name-Version (VLNV) matches
  # what was given in the synthesis script
  set add_0 [ create_bd_cell -type ip \
    -vlnv iitm.ac.in:ee5332:add:1.0 \
    add_0 ]
  ###### Other standard modules below.  Customization later ###

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip \
    -vlnv xilinx.com:ip:processing_system7:5.5 \
    processing_system7_0 ]
  set_property -dict [ list \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
  ] $processing_system7_0

  # Create instance: ps7_0_axi_periph, and set properties
  set ps7_0_axi_periph [ create_bd_cell -type ip \
    -vlnv xilinx.com:ip:axi_interconnect:2.1 \
    ps7_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
  ] $ps7_0_axi_periph

  # Create instance: rst_ps7_0_50M, and set properties
  set rst_ps7_0_50M [ create_bd_cell -type ip \
    -vlnv xilinx.com:ip:proc_sys_reset:5.0 \
    rst_ps7_0_50M ]

  # Create interface connections
  connect_bd_intf_net -intf_net processing_system7_0_DDR \
    [get_bd_intf_ports DDR] \
    [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO \
    [get_bd_intf_ports FIXED_IO] \
    [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 \
    [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]

  ##### This is custom for our design: clock, reset etc.
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI \
    [get_bd_intf_pins add_0/s_axi_control] \
    [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 \
    [get_bd_pins add_0/ap_clk] \
    [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins ps7_0_axi_periph/ACLK] \
    [get_bd_pins ps7_0_axi_periph/M00_ACLK] \
    [get_bd_pins ps7_0_axi_periph/S00_ACLK] \
    [get_bd_pins rst_ps7_0_50M/slowest_sync_clk]
  # Reset
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N \
    [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins rst_ps7_0_50M/ext_reset_in]
  connect_bd_net -net rst_ps7_0_50M_peripheral_aresetn \
    [get_bd_pins add_0/ap_rst_n] \
    [get_bd_pins ps7_0_axi_periph/ARESETN] \
    [get_bd_pins ps7_0_axi_periph/M00_ARESETN] \
    [get_bd_pins ps7_0_axi_periph/S00_ARESETN] \
    [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]

  ##### Create address segments
  assign_bd_address -offset 0x40000000 \
    -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs add_0/s_axi_control/Reg] -force

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_pynq()
cr_bd_pynq ""
set_property REGISTERED_WITH_MANAGER "1" [get_files pynq.bd ] 
set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files pynq.bd ] 

#call make_wrapper to create wrapper files
set wrapper_path [make_wrapper -fileset sources_1 \
  -files [ get_files -norecurse pynq.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path


#### Set up the synthesis and implementation runs
# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 \
    -part xc7z020clg400-1 \
    -flow {Vivado Synthesis 2021} \
    -strategy "Vivado Synthesis Defaults" \
    -report_strategy {No Reports} \
    -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2021" [get_runs synth_1]
}

if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 \
    -part xc7z020clg400-1 \
    -flow {Vivado Implementation 2021} \
    -strategy "Vivado Implementation Defaults" \
    -report_strategy {No Reports} \
    -constrset constrs_1 \
    -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2021" [get_runs impl_1]
}

#### Actually run the synthesis and implementation
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

#### Check the status of the runs.  If they completed successfully, 
# then copy the .bit and .hwh file to the build directory
# The hwh file will be present in the .gen folder, not the impl folder
set impl_status [get_property status [get_runs impl_1]]
if { $impl_status eq "write_bitstream Complete!" } {
  set project_path [get_property directory [current_project]]
  set project_file [file rootname $project_path]
  set __project [current_project]
  set hw_dir [file dirname [get_files *.hwh]]
  set hwhandoff [glob [file join $hw_dir *.hwh]]
  set bitstream [glob [file join $project_path $__project.runs impl_1 *.bit]]

  #gather in the .prj directory
  file copy -force $hwhandoff $project_file.hwh
  file copy -force $bitstream $project_file.bit
  puts "The .bit and .hwh files should be available now in $project_path.bit (and .hwh respectively)"
  puts "Copy them over to the Pynq board using scp or rsync"
} else {
  puts "Implementation failed.  Check the logs."
}
# Close the project
close_project
