set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir ..]]

if {[llength $argv] > 0} {
    set project_file_arg [lindex $argv 0]
} else {
    set project_file_arg [file join build vivado AXI_Peripheral.xpr]
}

if {[file pathtype $project_file_arg] eq "relative"} {
    set project_file [file normalize [file join $repo_root $project_file_arg]]
} else {
    set project_file [file normalize $project_file_arg]
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

proc normalize_file_list {files} {
    set out [list]
    foreach path $files {
        lappend out [file normalize $path]
    }
    return $out
}

proc assert_file_in_fileset {fileset_name required_file} {
    set fileset_files [normalize_file_list [get_files -quiet -of_objects [get_filesets $fileset_name]]]
    set required [file normalize $required_file]

    if {[lsearch -exact $fileset_files $required] < 0} {
        error "Required file is missing from $fileset_name: $required"
    }
}

proc assert_file_not_in_fileset {fileset_name forbidden_token} {
    set fileset_files [normalize_file_list [get_files -quiet -of_objects [get_filesets $fileset_name]]]
    foreach path $fileset_files {
        if {[string first $forbidden_token [string tolower $path]] >= 0} {
            error "Forbidden path found in $fileset_name: $path"
        }
    }
}

proc assert_dut_instance {tb_file} {
    set fd [open $tb_file r]
    set content [read $fd]
    close $fd

    if {![regexp {[^A-Za-z0-9_]dut[^A-Za-z0-9_]} $content]} {
        error "DUT instance named 'dut' was not found in $tb_file"
    }
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

if {![file exists $project_file]} {
    error "Vivado project was not found: $project_file"
}

open_project $project_file

set bd_files [get_files -quiet */AXI_Peripheral.bd]
if {[llength $bd_files] != 1} {
    error "Expected one AXI_Peripheral.bd, found [llength $bd_files]"
}
open_bd_design [lindex $bd_files 0]

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

foreach ip_hdl_dir [glob -nocomplain -types d [file join $repo_root ip *_1.0 hdl]] {
    foreach hdl_file [collect_hdl_files $ip_hdl_dir ""] {
        assert_file_in_fileset sim_1 $hdl_file
    }
}

foreach tb_file [list \
    tb/tb_iic.sv \
    tb/tb_rtl_timer_counter.sv \
    tb/tb_spi.sv \
    tb/tb_timer.sv \
    tb/tb_uart.sv \
] {
    set full_path [file join $repo_root $tb_file]
    assert_file_in_fileset sim_1 $full_path
    assert_dut_instance $full_path
}

assert_file_not_in_fileset sim_1 "/tb/spi_uvm/"

puts "Project check passed: SPI sdo/sdi wiring, IIC wiring, simulation sources, and dut instances are valid."
