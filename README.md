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
