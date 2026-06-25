set script_dir [file normalize [file dirname [info script]]]
set project_file [file join $script_dir "260625_MicroBlaze_GPIO.xpr"]
set xsa_dir [file normalize [file join $script_dir "XSA"]]
set xsa_file [file join $xsa_dir "stopwatch_design_wrapper.xsa"]

foreach board_repo_dir [list "/home/user/local-board-repos" "/local-board-repos"] {
    if {[file exists $board_repo_dir]} {
        puts "== Use board repository: $board_repo_dir"
        set_param board.repoPaths $board_repo_dir
        break
    }
}

puts "== Open project: $project_file"
open_project $project_file

puts "== Refresh local IP repository"
set hello_root [file normalize [file join $script_dir ".."]]
set ip_repo_dir [file join $hello_root "ip_repo" "gpio_1.0"]
if {[file exists $ip_repo_dir]} {
    set_property ip_repo_paths $ip_repo_dir [current_project]
    update_ip_catalog -rebuild
}

puts "== Validate and regenerate block design"
set bd_files [get_files -quiet *stopwatch_design.bd]
if {[llength $bd_files] == 0} {
    error "stopwatch_design.bd not found in project"
}
set bd_file [lindex $bd_files 0]
open_bd_design $bd_file
validate_bd_design
save_bd_design
generate_target all $bd_file

puts "== Update compile order"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "== Launch synthesis"
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "synth_1 status: [get_property STATUS [get_runs synth_1]]"
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "synth_1 did not complete. Check 260625_MicroBlaze_GPIO.runs/synth_1/stopwatch_design_wrapper.vds"
}

puts "== Launch implementation through write_bitstream"
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "impl_1 status: [get_property STATUS [get_runs impl_1]]"
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "impl_1 did not complete. Check 260625_MicroBlaze_GPIO.runs/impl_1/runme.log"
}

set bit_files [glob -nocomplain [file join $script_dir "260625_MicroBlaze_GPIO.runs" "impl_1" "*.bit"]]
if {[llength $bit_files] == 0} {
    error "BIT file was not created under 260625_MicroBlaze_GPIO.runs/impl_1"
}
puts "== BIT file: [lindex $bit_files 0]"

file mkdir $xsa_dir
puts "== Export hardware platform: $xsa_file"
write_hw_platform -fixed -include_bit -force -file $xsa_file

puts "== Done"
puts "XSA: $xsa_file"
close_project
