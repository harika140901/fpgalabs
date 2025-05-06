# Common definitions for compiling VHLS modules
# - Directories relative to script folder
# - module name should correspond to C function to be synthesized
# - TCL script for module should have same base name as module

set builddir ../build/vhls
# srcdir has to be given relative to the builddir above.  Hence the complex path
set srcdir ../../hls
set Vendor "iitm.ac.in"
set Library "ee5332"
set Taxonomy "/EE5332"

# Set part number, flow, clock etc.
proc setupProj { projName srcFiles tbFiles } {
	global builddir srcdir
	cd $builddir
	open_project $projName
	# Add source files to be synthesized
	foreach f $srcFiles {
		add_files $srcdir/$f
	}
	# Add test bench files needed for simulations
	foreach f $tbFiles {
		add_files -tb $srcdir/$f
	}
	set_top $projName

	# Open a custom solution and set parameters
	open_solution "pynq" -flow_target vivado
	# Use the DEAL board part number
	set_part {xc7z020clg400-1}
	create_clock -period 10 -name default
	config_rtl -kernel_profile=0 -module_auto_prefix -mult_keep_attribute -reset state -reset_async=0 -reset_level low 
}

proc synthAndExport { desc version } {
	global Vendor Library Taxonomy
	csynth_design
	#cosim_design
	export_design -format ip_catalog \
		-description $desc \
		-vendor $Vendor \
		-library $Library \
		-version $version \
		-display_name $desc \
		-taxonomy $Taxonomy
}

