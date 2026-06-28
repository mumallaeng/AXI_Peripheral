set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ..]]

set project_name AXI_Peripheral
if {[llength $argv] > 0} {
    set project_dir_arg [lindex $argv 0]
    if {[file pathtype $project_dir_arg] eq "relative"} {
        set project_dir [file normalize [file join $repo_root $project_dir_arg]]
    } else {
        set project_dir [file normalize $project_dir_arg]
    }
} else {
    set project_dir [file join $repo_root build vivado]
}

if {[llength $argv] > 1} {
    set xsa_file_arg [lindex $argv 1]
} else {
    set xsa_file_arg [file join build hw AXI_Peripheral_wrapper.xsa]
}
if {[file pathtype $xsa_file_arg] eq "relative"} {
    set xsa_file [file normalize [file join $repo_root $xsa_file_arg]]
} else {
    set xsa_file [file normalize $xsa_file_arg]
}

proc collect_hdl_files {root_dir exclude_token} {
    set files [list]

    if {![file isdirectory $root_dir]} {
        return $files
    }

    foreach path [glob -nocomplain -directory $root_dir -- *] {
        set normalized [file normalize $path]
        set lower_path [string tolower $normalized]

        if {$exclude_token ne "" && [string first $exclude_token $lower_path] >= 0} {
            continue
        }

        if {[file isdirectory $normalized]} {
            set files [concat $files [collect_hdl_files $normalized $exclude_token]]
            continue
        }

        set ext [string tolower [file extension $normalized]]
        if {[lsearch -exact [list .v .sv .vh .svh] $ext] >= 0} {
            lappend files $normalized
        }
    }

    return $files
}

proc assert_bd_port_connected {port_name pin_name} {
    set port_obj [get_bd_ports -quiet $port_name]
    set pin_obj [get_bd_pins -quiet $pin_name]

    if {[llength $port_obj] != 1} {
        error "Expected one BD port '$port_name', found [llength $port_obj]"
    }
    if {[llength $pin_obj] != 1} {
        error "Expected one BD pin '$pin_name', found [llength $pin_obj]"
    }

    set port_nets [get_bd_nets -quiet -of_objects $port_obj]
    set pin_nets [get_bd_nets -quiet -of_objects $pin_obj]
    if {[llength $port_nets] == 0 || [llength $pin_nets] == 0} {
        error "BD connection missing between port '$port_name' and pin '$pin_name'"
    }
    if {[lindex $port_nets 0] ne [lindex $pin_nets 0]} {
        error "BD port '$port_name' is not connected to pin '$pin_name'"
    }
}

proc assert_axi_peripheral_bd {} {
    foreach forbidden_pin [list mosi miso] {
        if {[llength [get_bd_pins -quiet spi_0/$forbidden_pin]] > 0} {
            error "Unexpected SPI pin spi_0/$forbidden_pin found. Use sdo/sdi in this project."
        }
    }

    foreach required_pin [list sclk sdo sdi cs_n intr] {
        if {[llength [get_bd_pins -quiet spi_0/$required_pin]] != 1} {
            error "Expected SPI pin spi_0/$required_pin was not found"
        }
    }

    assert_bd_port_connected sclk spi_0/sclk
    assert_bd_port_connected sdo spi_0/sdo
    assert_bd_port_connected sdi spi_0/sdi
    assert_bd_port_connected cs_n spi_0/cs_n
    assert_bd_port_connected scl iic_0/scl
    assert_bd_port_connected sda iic_0/sda
}

set repo_root_with_sep [file normalize [file join $repo_root .]]
set project_dir_with_sep [file normalize [file join $project_dir .]]
if {$project_dir_with_sep ne $repo_root_with_sep && [string first "${repo_root_with_sep}/" $project_dir_with_sep] != 0} {
    error "Project directory must be inside the repository so generated xpr paths stay portable: $project_dir"
}

set board_repo_candidates [list]
if {[info exists ::env(AXI_PERIPHERAL_BOARD_REPO)] && $::env(AXI_PERIPHERAL_BOARD_REPO) ne ""} {
    lappend board_repo_candidates $::env(AXI_PERIPHERAL_BOARD_REPO)
}
lappend board_repo_candidates \
    [file join $repo_root .. .worktrees vivado-2020.2 local-board-repos] \
    /home/user/local-board-repos

set board_repo_paths [list]
foreach board_repo $board_repo_candidates {
    set normalized_board_repo [file normalize $board_repo]
    if {[file isdirectory $normalized_board_repo]} {
        lappend board_repo_paths $normalized_board_repo
    }
}
if {[llength $board_repo_paths] > 0} {
    set_param board.repoPaths $board_repo_paths
}

file mkdir $project_dir
create_project $project_name $project_dir -part xc7a35tcpg236-1 -force
config_ip_cache -disable_cache

set board_part_name digilentinc.com:basys3:part0:1.2
if {[llength [get_board_parts -quiet $board_part_name]] > 0} {
    set_property board_part $board_part_name [current_project]
} else {
    puts "WARNING: Board part not found: $board_part_name"
}

set_property ip_repo_paths [list [file join $repo_root ip]] [current_project]
update_ip_catalog -rebuild

add_files -fileset constrs_1 -norecurse [file join $repo_root AXI_Peripheral.xdc]
source [file join $repo_root scripts create_bd.tcl]
assert_axi_peripheral_bd

set sim_files [list]
foreach ip_hdl_dir [glob -nocomplain -types d [file join $repo_root ip *_1.0 hdl]] {
    set sim_files [concat $sim_files [collect_hdl_files $ip_hdl_dir ""]]
}
set sim_files [concat $sim_files [collect_hdl_files [file join $repo_root tb] "uvm"]]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 -norecurse $sim_files
}

set bd_files [get_files -quiet */AXI_Peripheral.bd]
generate_target all $bd_files
set wrapper_file [file join $project_dir ${project_name}.gen sources_1 bd AXI_Peripheral hdl AXI_Peripheral_wrapper.v]
if {![file exists $wrapper_file]} {
    error "Generated wrapper not found: $wrapper_file"
}
add_files -fileset sources_1 -norecurse $wrapper_file
set_property top AXI_Peripheral_wrapper [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set xsa_dir [file dirname $xsa_file]
file mkdir $xsa_dir
write_hw_platform -fixed -force $xsa_file

puts "Created Vivado project: [file join $project_dir ${project_name}.xpr]"
puts "Exported hardware platform: $xsa_file"
