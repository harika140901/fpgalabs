# Script to add the required files and create the BD.
# This is meant for the adder demo, but can be adapted for other designs.
# The main difficulty will be in changing the AXI port mappings.
# Note: this script will fail if the project already exists
#       so ideally delete ../build before running this and the VHLS script

set build_dir "../build/vivado"
set _xil_proj_name_ "mult_stream_pynq"
# Define the IP's VLNV (the type of IP you want to instantiate)
set ip_vendor "iitm.ac.in"
set ip_library "ee5332"

set ip_type "mult_constant"
set ip_name "mult_constant_0"
set ip_version "1.0"
set ip_vlnv "$ip_vendor:$ip_library:$ip_type:$ip_version"

proc create_proj { } {
  global build_dir _xil_proj_name_ ip_vlnv
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
    global ip_name ip_vlnv

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
    set ip_inst [ create_bd_cell -type ip \
      -vlnv "$ip_vlnv" \
      ip_inst ]
    ###### Other standard modules below.  Customization later ###

    # Create instance: processing_system7_0, and set properties
    set processing_system7_0 [ create_bd_cell -type ip -vlnv \
      xilinx.com:ip:processing_system7:5.5 \
      processing_system7_0 ]
    set_property -dict [ list \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
    CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
    CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
    CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_S_AXI_HP1 {0} \
    CONFIG.PCW_USE_S_AXI_HP2 {0} \
    ] $processing_system7_0

    # Create instance: axi_dma_0, and set properties
    set axi_dma_0 [ create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axi_dma:7.1 \
      axi_dma_0 ]
    set_property -dict [ list \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {26} \
    ] $axi_dma_0

  #   CONFIG.c_m_axi_mm2s_data_width {64} \
  #   CONFIG.c_m_axis_mm2s_tdata_width {64} \

    # Create instance: axi_mem_intercon, and set properties
    set axi_mem_intercon [ create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axi_interconnect:2.1 \
      axi_mem_intercon ]
    set_property -dict [ list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {2} \
    ] $axi_mem_intercon

    # Create instance: ps7_0_axi_periph, and set properties
    set ps7_0_axi_periph [ create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axi_interconnect:2.1 \
      ps7_0_axi_periph ]
    set_property -dict [ list \
    CONFIG.NUM_MI {2} \
    ] $ps7_0_axi_periph

    # Create instance: rst_ps7_0_50M, and set properties
    set rst_ps7_0_50M [ create_bd_cell -type ip \
      -vlnv xilinx.com:ip:proc_sys_reset:5.0 \
      rst_ps7_0_50M ]

    # Create instance: system_ila_0, and set properties
    set system_ila_0 [ create_bd_cell -type ip \
      -vlnv xilinx.com:ip:system_ila:1.1 \
      system_ila_0 ]
    set_property -dict [ list \
    CONFIG.C_BRAM_CNT {6} \
    CONFIG.C_NUM_MONITOR_SLOTS {4} \
    CONFIG.C_SLOT {2} \
    CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
    CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
  ] $system_ila_0

    # Create interface connections
    connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S \
      [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] \
      [get_bd_intf_pins ip_inst/in_data]
    connect_bd_intf_net -intf_net ip_inst_out_data_V \
      [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] \
      [get_bd_intf_pins ip_inst/out_data]
    connect_bd_intf_net -intf_net processing_system7_0_DDR \
      [get_bd_intf_ports DDR] \
      [get_bd_intf_pins processing_system7_0/DDR]
    connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO \
      [get_bd_intf_ports FIXED_IO] \
      [get_bd_intf_pins processing_system7_0/FIXED_IO]
    connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 \
      [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
      [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
    connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI \
      [get_bd_intf_pins ip_inst/s_axi_control] \
      [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]
    connect_bd_intf_net -intf_net ps7_0_axi_periph_M01_AXI \
      [get_bd_intf_pins axi_dma_0/S_AXI_LITE] \
      [get_bd_intf_pins ps7_0_axi_periph/M01_AXI]

    connect_bd_intf_net -intf_net axi_dma_0_M_AXI_MM2S \
      [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] \
      [get_bd_intf_pins axi_mem_intercon/S00_AXI]
    connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM \
      [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] \
      [get_bd_intf_pins axi_mem_intercon/S01_AXI]
    connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI \
      [get_bd_intf_pins axi_mem_intercon/M00_AXI] \
      [get_bd_intf_pins processing_system7_0/S_AXI_HP0]


    # ILA connections
    connect_bd_intf_net -intf_net [get_bd_intf_nets axi_dma_0_M_AXIS_MM2S] \
      [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S] \
      [get_bd_intf_pins system_ila_0/SLOT_0_AXIS]
    connect_bd_intf_net -intf_net [get_bd_intf_nets ip_inst_out_data_V] \
      [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] \
      [get_bd_intf_pins system_ila_0/SLOT_1_AXIS]
    connect_bd_intf_net -intf_net [get_bd_intf_nets axi_dma_0_M_AXI_MM2S] \
      [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] \
      [get_bd_intf_pins system_ila_0/SLOT_2_AXI]
    connect_bd_intf_net -intf_net [get_bd_intf_nets axi_dma_0_M_AXI_S2MM] \
      [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] \
      [get_bd_intf_pins system_ila_0/SLOT_3_AXI]

    ##### clock and reset
    connect_bd_net -net processing_system7_0_FCLK_CLK0 \
      [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] \
      [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] \
      [get_bd_pins axi_dma_0/s_axi_lite_aclk] \
      [get_bd_pins axi_mem_intercon/ACLK] \
      [get_bd_pins axi_mem_intercon/M00_ACLK] \
      [get_bd_pins axi_mem_intercon/S00_ACLK] \
      [get_bd_pins axi_mem_intercon/S01_ACLK] \
      [get_bd_pins ip_inst/ap_clk] \
      [get_bd_pins processing_system7_0/FCLK_CLK0] \
      [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
      [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] \
      [get_bd_pins ps7_0_axi_periph/ACLK] \
      [get_bd_pins ps7_0_axi_periph/M00_ACLK] \
      [get_bd_pins ps7_0_axi_periph/M01_ACLK] \
      [get_bd_pins ps7_0_axi_periph/S00_ACLK] \
      [get_bd_pins rst_ps7_0_50M/slowest_sync_clk] \
      [get_bd_pins system_ila_0/clk]
    connect_bd_net -net processing_system7_0_FCLK_RESET0_N \
      [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
      [get_bd_pins rst_ps7_0_50M/ext_reset_in]
    connect_bd_net -net rst_ps7_0_50M_peripheral_aresetn \
      [get_bd_pins axi_dma_0/axi_resetn] \
      [get_bd_pins axi_mem_intercon/ARESETN] \
      [get_bd_pins axi_mem_intercon/M00_ARESETN] \
      [get_bd_pins axi_mem_intercon/S00_ARESETN] \
      [get_bd_pins axi_mem_intercon/S01_ARESETN] \
      [get_bd_pins ip_inst/ap_rst_n] \
      [get_bd_pins ps7_0_axi_periph/ARESETN] \
      [get_bd_pins ps7_0_axi_periph/M00_ARESETN] \
      [get_bd_pins ps7_0_axi_periph/M01_ARESETN] \
      [get_bd_pins ps7_0_axi_periph/S00_ARESETN] \
      [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] \
      [get_bd_pins system_ila_0/resetn]

    ##### Create address segments
    assign_bd_address -offset 0x00000000 \
      -range 0x20000000 \
      -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] \
      [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] \
      -force
    assign_bd_address -offset 0x00000000 \
      -range 0x20000000 \
      -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] \
      [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] \
      -force
    assign_bd_address -offset 0x41E00000 \
      -range 0x00010000 \
      -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
      [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] -force
    assign_bd_address -offset 0x40000000 \
      -range 0x00010000 \
      -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
      [get_bd_addr_segs ip_inst/s_axi_control/Reg] -force

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
}

proc setup_runs { } {
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
}

proc execute_runs { } {
  #### Actually run the synthesis and implementation
  launch_runs impl_1 -to_step write_bitstream -jobs 8
  wait_on_run impl_1
}


proc check_status { } {
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
    puts "The .bit and .hwh files should be available now in $project_path"
    puts "Copy them over to the Pynq board using scp or rsync"
  } else {
    puts "Implementation failed.  Check the logs."
  }
}

# Run the script
create_proj
setup_runs
execute_runs
check_status
close_project
