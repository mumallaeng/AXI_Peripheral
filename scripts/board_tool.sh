#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  ./scripts/board_tool.sh
  ./scripts/board_tool.sh build
  ./scripts/board_tool.sh program
  ./scripts/board_tool.sh serial
  ./scripts/board_tool.sh run
  ./scripts/board_tool.sh bitstream
  ./scripts/board_tool.sh list-serial

Actions:
  build        Regenerate the Vitis platform and build the AXI_Peripheral app.
  bitstream    Run Vivado implementation and generate the hardware bitstream.
  program      Inject the app ELF into the bitstream, then program the board.
  serial       Open the firmware serial console with tio.
  run          Build, program, then open the serial console.
  list-serial  List macOS USB serial ports.

Options:
  --port PATH       Serial port path. Auto-detected when omitted.
  --baud RATE      Serial baud rate. Default: 9600.
  --container NAME Docker container name. Default: vivado_container.
  --board NAME     openFPGALoader board name. Default: basys3.
  --no-platform    Skip platform regeneration during build.
  --no-upload      Create *_with_elf.bit only. Do not program the board.
  --dry-run        Print commands without running build, updatemem, or upload.
  -h, --help       Show this help.

Notes:
  This script currently supports the macOS host + Docker Vivado/Vitis flow only.
  Exit tio with Ctrl-t, then q.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

action="${1:-menu}"
if [[ "${action}" != --* && "$#" -gt 0 ]]; then
    shift
else
    action="menu"
fi

container="${VIVADO_DOCKER_CONTAINER:-vivado_container}"
board="${AXI_PERIPHERAL_BOARD:-basys3}"
baud="${AXI_PERIPHERAL_SERIAL_BAUD:-9600}"
port=""
regen_platform=1
upload=1
dry_run=0

project_name="AXI_Peripheral"
workspace_dir="$repo_root/firmware"
project_dir="$repo_root/build/vivado"
xpr_path="$project_dir/$project_name.xpr"
xsa_path="${AXI_PERIPHERAL_XSA:-$repo_root/build/hw/AXI_Peripheral_wrapper.xsa}"
elf_path="$workspace_dir/$project_name/Debug/$project_name.elf"
bit_path="$project_dir/${project_name}.runs/impl_1/${project_name}_wrapper.bit"
mmi_path="$project_dir/${project_name}.runs/impl_1/${project_name}_wrapper.mmi"
out_bit_path="$project_dir/${project_name}.runs/impl_1/${project_name}_wrapper_with_elf.bit"
proc_path="${AXI_PERIPHERAL_PROC:-${project_name}_i/microblaze_0}"
vivado_jobs="${AXI_PERIPHERAL_VIVADO_JOBS:-4}"

while (($#)); do
    case "$1" in
        --port)
            port="${2:?missing value for --port}"
            shift 2
            ;;
        --baud)
            baud="${2:?missing value for --baud}"
            shift 2
            ;;
        --container)
            container="${2:?missing value for --container}"
            shift 2
            ;;
        --board)
            board="${2:?missing value for --board}"
            shift 2
            ;;
        --no-platform)
            regen_platform=0
            shift
            ;;
        --no-upload)
            upload=0
            shift
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

require_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "Unsupported host OS: $(uname -s)" >&2
        echo "This script currently supports only the macOS host + Docker Vivado/Vitis flow." >&2
        exit 2
    fi
}

need_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
}

need_file() {
    local path="$1"
    local label="$2"
    if [[ ! -f "$path" ]]; then
        echo "Missing $label: $path" >&2
        exit 1
    fi
}

to_docker_path() {
    local path="$1"
    case "$path" in
        /Users/mumallaeng/git/*)
            printf '/home/user/git/%s\n' "${path#/Users/mumallaeng/git/}"
            ;;
        *)
            echo "Path is not under Docker-mounted /Users/mumallaeng/git: $path" >&2
            exit 2
            ;;
    esac
}

ensure_container_running() {
    need_command docker

    local container_state
    container_state="$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || true)"
    case "$container_state" in
        running)
            ;;
        created|exited|paused|restarting|dead)
            echo "Starting Docker container: $container"
            docker start "$container" >/dev/null
            ;;
        *)
            echo "Docker container not found: $container" >&2
            exit 1
            ;;
    esac
}

run_container_bash() {
    local settings_path="$1"
    shift

    ensure_container_running
    docker exec \
        -e D_REPO_ROOT="$(to_docker_path "$repo_root")" \
        -e D_WORKSPACE="$(to_docker_path "$workspace_dir")" \
        -e D_XPR="$(to_docker_path "$xpr_path")" \
        -e D_XSA="$(to_docker_path "$xsa_path")" \
        -e D_ELF="$(to_docker_path "$elf_path")" \
        -e D_BIT="$(to_docker_path "$bit_path")" \
        -e D_MMI="$(to_docker_path "$mmi_path")" \
        -e D_OUT_BIT="$(to_docker_path "$out_bit_path")" \
        -e D_PROC="$proc_path" \
        -e D_PROJECT="$project_name" \
        -e D_VIVADO_JOBS="$vivado_jobs" \
        -e D_REGEN_PLATFORM="$regen_platform" \
        "$container" bash -lc "
set -euo pipefail
source '$settings_path' >/dev/null 2>&1
$*
"
}

list_serial_ports() {
    for pattern in \
        /dev/cu.usbserial* \
        /dev/cu.usbmodem* \
        /dev/cu.SLAB_USBtoUART* \
        /dev/cu.wchusbserial* \
        /dev/cu.usb*; do
        for candidate in $pattern; do
            [[ -e "$candidate" ]] && printf '%s\n' "$candidate"
        done
    done | awk '!seen[$0]++'
}

select_serial_port() {
    if [[ -n "$port" ]]; then
        printf '%s\n' "$port"
        return
    fi

    local ports port_count selected index
    ports="$(list_serial_ports || true)"
    port_count="$(printf '%s\n' "$ports" | sed '/^$/d' | wc -l | tr -d ' ')"

    if [[ "$port_count" == "0" ]]; then
        echo "No macOS USB serial port found." >&2
        echo "Connect the board, then check ports with:" >&2
        echo "  ./scripts/board_tool.sh list-serial" >&2
        exit 1
    fi

    if [[ "$port_count" == "1" ]]; then
        printf '%s\n' "$ports" | sed '/^$/d' | sed -n '1p'
        return
    fi

    echo "Multiple USB serial ports found:" >&2
    printf '%s\n' "$ports" | sed '/^$/d' | nl -w1 -s') ' >&2
    printf 'Select port number: ' >&2
    read -r index
    selected="$(printf '%s\n' "$ports" | sed '/^$/d' | sed -n "${index}p")"
    if [[ -z "$selected" ]]; then
        echo "Invalid port selection: $index" >&2
        exit 1
    fi
    printf '%s\n' "$selected"
}

build_firmware() {
    echo "== Build firmware =="
    echo "Workspace: $workspace_dir"
    echo "XSA      : $xsa_path"
    echo "App      : $project_name"

    need_file "$xsa_path" "XSA"

    if [[ "$dry_run" -eq 1 ]]; then
        echo "Dry run: regenerate platform, then build firmware sources with mb-gcc"
        return
    fi

    run_container_bash "/home/user/Xilinx/Vitis/2020.2/settings64.sh" '
cd "$D_WORKSPACE"
if [[ "$D_REGEN_PLATFORM" == "1" ]]; then
    AXI_PERIPHERAL_XSA="$D_XSA" env -u LD_PRELOAD -u LD_LIBRARY_PATH xsct AXI_Peripheral_platform/platform.tcl
fi

app_dir="$D_WORKSPACE/$D_PROJECT"
bsp_dir="$D_WORKSPACE/${D_PROJECT}_platform/microblaze_0/standalone_microblaze_0/bsp/microblaze_0"
build_dir="$app_dir/Debug"
obj_root="$build_dir/obj"

if [[ ! -d "$bsp_dir/include" || ! -f "$bsp_dir/lib/libxil.a" ]]; then
    echo "Missing BSP outputs under: $bsp_dir" >&2
    echo "Run platform regeneration first." >&2
    exit 1
fi

rm -rf "$build_dir"
mkdir -p "$obj_root"

objects=()
while IFS= read -r src; do
    rel="${src#$app_dir/src/}"
    obj="$obj_root/${rel%.c}.o"
    dep="${obj%.o}.d"
    mkdir -p "$(dirname "$obj")"
    env -u LD_PRELOAD -u LD_LIBRARY_PATH mb-gcc \
        -Wall -O0 -g3 -c -fmessage-length=0 \
        -I"$bsp_dir/include" -I"$app_dir/src" \
        -mlittle-endian -mcpu=v11.0 -mxl-soft-mul -Wl,--no-relax \
        -ffunction-sections -fdata-sections \
        -MMD -MP -MF"$dep" -MT"$obj" \
        -o "$obj" "$src"
    objects+=("$obj")
done < <(find "$app_dir/src" -name "*.c" | sort)

if [[ "${#objects[@]}" -eq 0 ]]; then
    echo "No firmware C sources found under: $app_dir/src" >&2
    exit 1
fi

env -u LD_PRELOAD -u LD_LIBRARY_PATH mb-gcc \
    -mlittle-endian -mcpu=v11.0 -mxl-soft-mul \
    -Wl,--no-relax -Wl,--gc-sections \
    -Wl,-T -Wl,"$app_dir/src/lscript.ld" \
    -L"$bsp_dir/lib" \
    -o "$D_ELF" "${objects[@]}" -lxil

ls -lh "$D_ELF"
'
}

build_bitstream() {
    echo "== Build hardware bitstream =="
    echo "XPR : $xpr_path"
    echo "BIT : $bit_path"
    echo "MMI : $mmi_path"

    need_file "$xpr_path" "Vivado project"

    if [[ "$dry_run" -eq 1 ]]; then
        echo "Dry run: launch Vivado impl_1 to write_bitstream with $vivado_jobs jobs"
        return
    fi

    run_container_bash "/home/user/Xilinx/Vivado/2020.2/settings64.sh" '
vivado -mode batch -source "$D_REPO_ROOT/scripts/build_bitstream.tcl" \
    -tclargs "$D_XPR" "$D_BIT" "$D_MMI" "$D_VIVADO_JOBS"
'

    need_file "$bit_path" "generated bitstream"
    need_file "$mmi_path" "generated MMI"
}

ensure_bitstream() {
    if [[ -f "$bit_path" && -f "$mmi_path" ]]; then
        return
    fi

    echo "Bitstream or MMI is missing; generating hardware bitstream first."
    build_bitstream
}

program_board() {
    echo "== Program board =="
    echo "ELF : $elf_path"
    echo "BIT : $bit_path"
    echo "MMI : $mmi_path"
    echo "OUT : $out_bit_path"
    echo "PROC: $proc_path"

    if [[ "$dry_run" -eq 1 ]]; then
        echo "Dry run: updatemem, then openFPGALoader -b $board $out_bit_path"
        return
    fi

    need_file "$elf_path" "Vitis ELF"
    ensure_bitstream

    if [[ -d "$workspace_dir/$project_name/src" ]]; then
        local newer_src
        newer_src="$(find "$workspace_dir/$project_name/src" -type f \( -name '*.c' -o -name '*.h' \) -newer "$elf_path" -print -quit)"
        if [[ -n "$newer_src" ]]; then
            echo "Warning: source is newer than ELF. Run build before programming if this is unexpected." >&2
            echo "Newer source: $newer_src" >&2
        fi
    fi

    run_container_bash "/home/user/Xilinx/Vivado/2020.2/settings64.sh" '
updatemem \
    -meminfo "$D_MMI" \
    -data "$D_ELF" \
    -bit "$D_BIT" \
    -proc "$D_PROC" \
    -out "$D_OUT_BIT" \
    -force
'

    if [[ "$upload" -eq 0 ]]; then
        echo "Created ELF-updated bitstream: $out_bit_path"
        return
    fi

    need_command openFPGALoader
    openFPGALoader -b "$board" "$out_bit_path"
}

open_serial_terminal() {
    echo "== Open serial terminal =="
    need_command tio

    if [[ "$dry_run" -eq 1 ]]; then
        if [[ -n "$port" ]]; then
            echo "Dry run: tio -b $baud -d 8 -p none -s 1 -f none $port"
        else
            echo "Dry run: tio -b $baud -d 8 -p none -s 1 -f none <selected serial port>"
            echo "Available ports:"
            list_serial_ports || true
        fi
        return
    fi

    local selected_port
    selected_port="$(select_serial_port)"
    if [[ ! -e "$selected_port" ]]; then
        echo "Serial port does not exist: $selected_port" >&2
        exit 1
    fi

    echo "Port: $selected_port"
    echo "Baud: $baud"
    echo "Mode: 8N1, no flow control"
    echo "Exit tio with Ctrl-t, then q."

    exec tio -b "$baud" -d 8 -p none -s 1 -f none "$selected_port"
}

show_menu() {
    cat <<'MENU'
AXI_Peripheral board tool

1) Build Vitis firmware
2) Program board
3) Open serial terminal
4) Build + program board
5) Build + program board + open serial terminal
6) Build hardware bitstream
7) List serial ports
8) Regenerate Vitis platform + build firmware

Select:
MENU
    read -r choice
    case "$choice" in
        1) action="build"; regen_platform=0 ;;
        2) action="program" ;;
        3) action="serial" ;;
        4) action="build-program"; regen_platform=0 ;;
        5) action="run"; regen_platform=0 ;;
        6) action="bitstream" ;;
        7) action="list-serial" ;;
        8) action="build"; regen_platform=1 ;;
        *) echo "Invalid selection: $choice" >&2; exit 2 ;;
    esac
}

require_macos

if [[ "$action" == "menu" ]]; then
    show_menu
fi

case "$action" in
    build)
        build_firmware
        ;;
    bitstream)
        build_bitstream
        ;;
    program)
        program_board
        ;;
    serial)
        open_serial_terminal
        ;;
    build-program)
        build_firmware
        program_board
        ;;
    run)
        build_firmware
        program_board
        open_serial_terminal
        ;;
    list-serial)
        list_serial_ports
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Unknown action: $action" >&2
        usage >&2
        exit 2
        ;;
esac
