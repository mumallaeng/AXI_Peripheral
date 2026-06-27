# Re-create the Vitis platform project from the Vivado-exported XSA.
#
# Expected XSA:
#   AXI_Peripheral_wrapper.xsa

set script_dir [file dirname [file normalize [info script]]]
set workspace_dir [file dirname $script_dir]
set xsa_path [file join $script_dir hw AXI_Peripheral_wrapper.xsa]

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
