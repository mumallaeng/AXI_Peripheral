set script_dir [file normalize [file dirname [info script]]]
set project_file [file join $script_dir "260622_MicroBlaze_GPIO.xpr"]
set xsa_dir [file normalize [file join $script_dir ".." "XSA"]]
set xsa_file [file join $xsa_dir "GPIO_Test_wrapper.xsa"]

puts "== Open project: $project_file"
open_project $project_file

puts "== Update compile order"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "== Launch synthesis"
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "synth_1 status: [get_property STATUS [get_runs synth_1]]"
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "synth_1 did not complete. Check 260622_MicroBlaze_GPIO.runs/synth_1/GPIO_Test_wrapper.vds"
}

puts "== Launch implementation through write_bitstream"
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "impl_1 status: [get_property STATUS [get_runs impl_1]]"
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "impl_1 did not complete. Check 260622_MicroBlaze_GPIO.runs/impl_1/runme.log"
}

set bit_files [glob -nocomplain [file join $script_dir "260622_MicroBlaze_GPIO.runs" "impl_1" "*.bit"]]
if {[llength $bit_files] == 0} {
    error "BIT file was not created under 260622_MicroBlaze_GPIO.runs/impl_1"
}
puts "== BIT file: [lindex $bit_files 0]"

file mkdir $xsa_dir
puts "== Export hardware platform: $xsa_file"
write_hw_platform -fixed -include_bit -force -file $xsa_file

puts "== Done"
puts "XSA: $xsa_file"
close_project
