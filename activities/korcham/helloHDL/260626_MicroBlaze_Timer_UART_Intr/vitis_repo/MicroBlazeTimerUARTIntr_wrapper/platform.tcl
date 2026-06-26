# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/user/git/Vault/activities/korcham/helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/MicroBlazeTimerUARTIntr_wrapper/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/user/git/Vault/activities/korcham/helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo/MicroBlazeTimerUARTIntr_wrapper/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {MicroBlazeTimerUARTIntr_wrapper}\
-hw {/home/user/git/Vault/activities/korcham/helloHDL/260626_MicroBlaze_Timer_UART_Intr/XSA/MicroBlazeTimerUARTIntr_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {/home/user/git/Vault/activities/korcham/helloHDL/260626_MicroBlaze_Timer_UART_Intr/vitis_repo}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {MicroBlazeTimerUARTIntr_wrapper}
platform generate -quick
