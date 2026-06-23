set script_dir [file normalize [file dirname [info script]]]
set hello_root [file normalize [file join $script_dir ".."]]
set ip_repo_dir [file join $hello_root "ip_repo"]
set gpio_component [file join $ip_repo_dir "gpio_1.0" "component.xml"]
set project_file [file join $script_dir "260622_MicroBlaze_GPIO.xpr"]
set xsa_dir [file join $hello_root "XSA"]
set xsa_file [file join $xsa_dir "GPIO_Test_wrapper.xsa"]

puts "== Re-package GPIO custom IP"
set core [ipx::open_ipxact_file $gpio_component]
if {[catch {ipx::merge_project_changes files $core} merge_msg]} {
    puts "INFO: merge_project_changes skipped: $merge_msg"
}
ipx::update_checksums $core
ipx::check_integrity $core
ipx::save_core $core

puts "== Open project: $project_file"
open_project $project_file

puts "== Refresh IP catalog"
set_property ip_repo_paths $ip_repo_dir [current_project]
update_ip_catalog -rebuild
report_ip_status -name ip_status_after_repackage

set gpio_ips [get_ips -quiet *gpio*]
if {[llength $gpio_ips] > 0} {
    puts "== GPIO IP instances: $gpio_ips"
    set locked_ips [list]
    foreach ip $gpio_ips {
        set locked [get_property IS_LOCKED $ip]
        set upgrade [get_property UPGRADE_VERSIONS $ip]
        puts "IP $ip locked=$locked upgrade_versions=$upgrade"
        if {$locked || $upgrade ne ""} {
            lappend locked_ips $ip
        }
    }
    if {[llength $locked_ips] > 0} {
        puts "== Upgrade locked/outdated GPIO IP instances: $locked_ips"
        upgrade_ip $locked_ips
        report_ip_status
    }
}

puts "== Regenerate block design output products"
set bd_files [get_files -quiet *GPIO_Test.bd]
if {[llength $bd_files] == 0} {
    error "GPIO_Test.bd not found in project"
}
open_bd_design [lindex $bd_files 0]

puts "== Ensure Basys3 single-ended sys_clock input"
set clk_wiz [get_bd_cells -quiet clk_wiz_1]
if {[llength $clk_wiz] == 0} {
    error "clk_wiz_1 not found in block design"
}
set diff_clock_ports [get_bd_intf_ports -quiet diff_clock_rtl]
if {[llength $diff_clock_ports] > 0} {
    foreach diff_clock_port $diff_clock_ports {
        set diff_clock_nets [get_bd_intf_nets -quiet -of_objects $diff_clock_port]
        if {[llength $diff_clock_nets] > 0} {
            delete_bd_objs $diff_clock_nets
        }
        delete_bd_objs $diff_clock_port
    }
}
set_property -dict [list CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin}] $clk_wiz
set sys_clock [get_bd_ports -quiet sys_clock]
if {[llength $sys_clock] == 0} {
    set sys_clock [create_bd_port -dir I -type clk -freq_hz 100000000 sys_clock]
} else {
    set_property CONFIG.FREQ_HZ 100000000 $sys_clock
}
set clk_in_pin [get_bd_pins -quiet clk_wiz_1/clk_in1]
if {[llength $clk_in_pin] == 0} {
    error "clk_wiz_1/clk_in1 not found after switching clk_wiz_1 to single-ended input"
}
set clk_in_net [get_bd_nets -quiet -of_objects $clk_in_pin]
if {[llength $clk_in_net] == 0} {
    connect_bd_net -net sys_clock_1 $sys_clock $clk_in_pin
}

validate_bd_design
save_bd_design
generate_target all [lindex $bd_files 0]

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
