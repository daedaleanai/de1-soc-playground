
if { $argc != 1 } {
    puts "You need to specify the name of the project."
    exit 2
}

set name [lindex $argv 0]

project_open $name -revision $name

source system/synthesis/submodules/hps_sdram_p0_pin_assignments.tcl

project_close
