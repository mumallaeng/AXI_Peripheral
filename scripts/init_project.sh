#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

PROJECT_DIR=${1:-build/vivado}
XSA_PATH=${AXI_PERIPHERAL_XSA:-$REPO_ROOT/build/hw/AXI_Peripheral_wrapper.xsa}

find_tool() {
    tool_name=$1
    shift

    if command -v "$tool_name" >/dev/null 2>&1; then
        command -v "$tool_name"
        return 0
    fi

    for candidate in "$@"; do
        if [ -x "$candidate" ] || [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

VIVADO_BIN=${VIVADO:-}
if [ -z "$VIVADO_BIN" ]; then
    VIVADO_BIN=$(find_tool vivado \
        /c/Xilinx/Vivado/2020.2/bin/vivado.bat \
        /mnt/c/Xilinx/Vivado/2020.2/bin/vivado.bat \
        /home/user/Xilinx/Vivado/2020.2/bin/vivado \
        /opt/Xilinx/Vivado/2020.2/bin/vivado) || {
        echo "ERROR: Vivado 2020.2 was not found. Add vivado to PATH or set VIVADO=/path/to/vivado." >&2
        exit 1
    }
fi

XSCT_BIN=${XSCT:-}
if [ -z "$XSCT_BIN" ]; then
    XSCT_BIN=$(find_tool xsct \
        /c/Xilinx/Vitis/2020.2/bin/xsct.bat \
        /mnt/c/Xilinx/Vitis/2020.2/bin/xsct.bat \
        /home/user/Xilinx/Vitis/2020.2/bin/xsct \
        /opt/Xilinx/Vitis/2020.2/bin/xsct) || {
        echo "ERROR: Vitis XSCT 2020.2 was not found. Add xsct to PATH or set XSCT=/path/to/xsct." >&2
        exit 1
    }
fi

cd "$REPO_ROOT"

echo "Repository: $REPO_ROOT"
echo "Vivado    : $VIVADO_BIN"
echo "XSCT      : $XSCT_BIN"
echo "Project   : $PROJECT_DIR"
echo "XSA       : $XSA_PATH"

"$VIVADO_BIN" -mode batch -source scripts/create_project.tcl -tclargs "$PROJECT_DIR" "$XSA_PATH"
"$VIVADO_BIN" -mode batch -source scripts/check_project.tcl -tclargs "$PROJECT_DIR/AXI_Peripheral.xpr"

(
    cd firmware
    AXI_PERIPHERAL_XSA="$XSA_PATH" env -u LD_PRELOAD -u LD_LIBRARY_PATH "$XSCT_BIN" AXI_Peripheral_platform/platform.tcl
)

echo "Vivado project: $REPO_ROOT/$PROJECT_DIR/AXI_Peripheral.xpr"
echo "Vitis workspace: $REPO_ROOT/firmware"
