
if { $argc != 1 } {
    puts "You need to specify the name of the project."
    exit 2
}

set name [lindex $argv 0]

project_new $name -revision $name -overwrite

set_global_assignment -name TOP_LEVEL_ENTITY $name
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name VERILOG_FILE [concat $name ".v"]
set_global_assignment -name QIP_FILE system/synthesis/system.qip

set here [file dirname [info script]]
source [file join $here de1-soc-pin-assignment.tcl]

project_close
