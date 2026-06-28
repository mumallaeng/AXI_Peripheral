# AXI_Peripheral

## Vivado project generation

This repository does not track generated Vivado project files such as
`AXI_Peripheral.xpr`, `.bd`, generated wrapper files, `.xci`, or `ipshared`.
Generate the Vivado project from the repository root before opening the block
design.

To initialize the local Vivado project and regenerate the Vitis platform outputs:

```sh
./scripts/init_project.sh
```

By default, the Vivado project is generated at:

```text
build/vivado/AXI_Peripheral.xpr
```

The repository root intentionally does not contain `AXI_Peripheral.xpr`.
After running the initialization script, open this generated project instead:

```sh
open build/vivado/AXI_Peripheral.xpr
```

In Vivado, use `Open Project` and select:

```text
build/vivado/AXI_Peripheral.xpr
```

You can pass a different in-repository output directory:

```sh
./scripts/init_project.sh build/vivado
```

The output directory must stay inside this repository. This keeps generated
project paths portable across macOS, Windows Git Bash, WSL, and Linux.

The initialization script also exports a local hardware platform XSA to:

```text
build/hw/AXI_Peripheral_wrapper.xsa
```

## Manual Vivado generation

Generate only the Vivado project:

```sh
vivado -mode batch -source scripts/create_project.tcl -tclargs build/vivado
```

To refresh the tracked XSA intentionally, pass the tracked XSA path as the
second Tcl argument:

```sh
vivado -mode batch -source scripts/create_project.tcl -tclargs build/vivado firmware/hw/AXI_Peripheral_wrapper.xsa
```

Open the generated project:

```text
build/vivado/AXI_Peripheral.xpr
```

If Vivado is not in `PATH` on Windows, use the Vivado Tcl Shell from the Start
menu, or call `vivado.bat` directly.

PowerShell:

```powershell
& "C:\Xilinx\Vivado\2020.2\bin\vivado.bat" -mode batch -source scripts/create_project.tcl -tclargs build/vivado
```

Command Prompt:

```bat
"C:\Xilinx\Vivado\2020.2\bin\vivado.bat" -mode batch -source scripts/create_project.tcl -tclargs build/vivado
```

If Vivado is installed in a different location, replace
`C:\Xilinx\Vivado\2020.2\bin\vivado.bat` with the local install path.

## Manual Vitis platform regeneration

Open Vitis with `firmware/` as the workspace. Regenerate the local platform
outputs after clone, pull, or hardware updates:

```sh
cd firmware
env -u LD_PRELOAD -u LD_LIBRARY_PATH xsct AXI_Peripheral_platform/platform.tcl
```

On Windows:

```bat
cd firmware
xsct.bat AXI_Peripheral_platform\platform.tcl
```

## macOS board utility

`init_project.sh` is for regenerating the Vivado/Vitis project state. Board
bring-up actions such as Vitis firmware build, board programming, and serial
terminal logging are handled by:

```sh
./scripts/board_tool.sh
```

This script currently supports only the macOS host + Docker Vivado/Vitis flow.
It uses Docker for Vitis/Vivado CLI work, `openFPGALoader` for board upload, and
`tio` for the serial terminal.
The `build` action regenerates the Vitis platform/BSP when needed, then builds
the firmware sources directly with the MicroBlaze GCC toolchain.
The `program` and `run` actions automatically generate the Vivado bitstream
first when `build/vivado/AXI_Peripheral.runs/impl_1/AXI_Peripheral_wrapper.bit`
or the matching `.mmi` file is missing.

Common commands:

```sh
./scripts/board_tool.sh build
./scripts/board_tool.sh bitstream
./scripts/board_tool.sh program
./scripts/board_tool.sh serial
./scripts/board_tool.sh run
./scripts/board_tool.sh list-serial
```

Without an action, the script opens a numbered menu.

The serial terminal defaults to `9600` baud, `8N1`, and no flow control. To
select a port explicitly:

```sh
./scripts/board_tool.sh serial --port /dev/cu.usbserial-0001 --baud 9600
```

Exit `tio` with `Ctrl-t`, then `q`.
