if {[llength $argv] < 4} {
    error "Usage: build_bitstream.tcl <project.xpr> <bitfile> <mmi> <jobs>"
}

set project_file [file normalize [lindex $argv 0]]
set bit_file [file normalize [lindex $argv 1]]
set mmi_file [file normalize [lindex $argv 2]]
set jobs [lindex $argv 3]

if {![file exists $project_file]} {
    error "Vivado project was not found: $project_file"
}

open_project $project_file
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1

set run_status [get_property STATUS [get_runs impl_1]]
puts "impl_1 status: $run_status"
if {[string first "write_bitstream Complete" $run_status] < 0} {
    error "Vivado implementation did not complete bitstream generation: $run_status"
}

if {![file exists $bit_file]} {
    error "Generated bitstream was not found: $bit_file"
}
if {![file exists $mmi_file]} {
    error "Generated MMI was not found: $mmi_file"
}

puts "Generated bitstream: $bit_file"
puts "Generated MMI: $mmi_file"
close_project
