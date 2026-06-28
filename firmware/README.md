# Firmware Workspace

Open Vitis with this directory as the workspace:

```sh
firmware/
```

The repository tracks the firmware sources, Vitis project descriptors, the
platform Tcl script, and the Vivado-exported XSA input. Generated platform
outputs are intentionally not tracked.

Tracked platform inputs:

```text
AXI_Peripheral_platform/platform.tcl
hw/AXI_Peripheral_wrapper.xsa
```

Regenerate the platform outputs after clone, pull, or hardware updates:

```sh
cd firmware
env -u LD_PRELOAD -u LD_LIBRARY_PATH xsct AXI_Peripheral_platform/platform.tcl
```

On Windows, run the same command from a Vitis 2020.2 command prompt:

```bat
cd firmware
xsct.bat AXI_Peripheral_platform\platform.tcl
```

Regenerated paths such as `AXI_Peripheral_platform/export/`,
`AXI_Peripheral_platform/microblaze_0/`, `AXI_Peripheral_platform/tempdsa/`,
`AXI_Peripheral_platform/platform.spr`, `Debug/`, and `Release/` are local
build products.
