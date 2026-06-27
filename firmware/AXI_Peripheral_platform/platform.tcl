# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\kccistc\Desktop\AXI_Peripheral\firmware\AXI_Peripheral_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\kccistc\Desktop\AXI_Peripheral\firmware\AXI_Peripheral_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {AXI_Peripheral_platform}\
-hw {C:\Users\kccistc\Desktop\AXI_Peripheral\XSA\AXI_Peripheral_wrapper.xsa}\
-proc {microblaze_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {C:/Users/kccistc/Desktop/AXI_Peripheral/firmware}

platform write
platform generate -domains 
platform active {AXI_Peripheral_platform}
platform config -updatehw {C:/Users/kccistc/Desktop/AXI_Peripheral/XSA/AXI_Peripheral_wrapper.xsa}
platform clean
platform active {AXI_Peripheral_platform}
platform config -updatehw {C:/Users/kccistc/Desktop/AXI_Peripheral/AXI_Peripheral_wrapper.xsa}
platform config -updatehw {C:/Users/kccistc/Desktop/AXI_Peripheral/AXI_Peripheral_wrapper.xsa}
platform clean
platform config -updatehw {C:/Users/kccistc/Desktop/AXI_Peripheral/AXI_Peripheral_wrapper.xsa}
