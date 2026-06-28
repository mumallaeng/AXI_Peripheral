# Re-create the Vitis platform project from the Vivado-exported XSA.
#
# Expected XSA:
#   ../hw/AXI_Peripheral_wrapper.xsa

set script_dir [file dirname [file normalize [info script]]]
set workspace_dir [file dirname $script_dir]
if {[info exists ::env(AXI_PERIPHERAL_XSA)] && $::env(AXI_PERIPHERAL_XSA) ne ""} {
    set xsa_path [file normalize $::env(AXI_PERIPHERAL_XSA)]
} else {
    set xsa_path [file join $workspace_dir hw AXI_Peripheral_wrapper.xsa]
}

# Vitis keeps generated BSP metadata such as system.mss under the platform
# project. Remove stale generated outputs before re-creating the platform so
# renamed BD IP instances do not leave old HW_INSTANCE entries behind.
foreach generated_path [list \
    [file join $script_dir export] \
    [file join $script_dir logs] \
    [file join $script_dir microblaze_0] \
    [file join $script_dir platform.spr] \
    [file join $script_dir tempdsa] \
] {
    if {[file exists $generated_path]} {
        file delete -force $generated_path
    }
}

platform create -name {AXI_Peripheral_platform} \
    -hw $xsa_path \
    -out $workspace_dir

platform write
domain create -name {standalone_microblaze_0} \
    -display-name {standalone_microblaze_0} \
    -os {standalone} \
    -proc {microblaze_0} \
    -runtime {cpp} \
    -arch {32-bit} \
    -support-app {empty_application}
platform generate -domains
platform active {AXI_Peripheral_platform}
platform generate -quick
platform generate -domains
platform generate
platform generate
