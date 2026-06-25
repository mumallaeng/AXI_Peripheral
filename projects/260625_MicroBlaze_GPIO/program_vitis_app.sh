#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  ./program_vitis_app.sh [options]

Default flow:
  1. Inject vitis_repo/StopWatch/Debug/StopWatch.elf into the implemented bitstream.
  2. Program the Basys3 board with the ELF-updated bitstream.

Options:
  --no-upload          Create *_with_elf.bit only. Do not program the board.
  --dry-run            Print commands without running updatemem or openFPGALoader.
  --elf PATH           Override Vitis application ELF path.
  --bit PATH           Override input Vivado bitstream path.
  --mmi PATH           Override MicroBlaze memory map info path.
  --out PATH           Override output bitstream path.
  --proc PATH          Override MicroBlaze instance path.
  --container NAME     Override Docker container name. Default: vivado_container.
  --board NAME         Override openFPGALoader board name. Default: basys3.
  -h, --help           Show this help.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

container="${VIVADO_DOCKER_CONTAINER:-vivado_container}"
board="basys3"
upload=1
dry_run=0

elf="$script_dir/vitis_repo/StopWatch/Debug/StopWatch.elf"
bit="$script_dir/260625_MicroBlaze_GPIO.runs/impl_1/stopwatch_design_wrapper.bit"
mmi="$script_dir/260625_MicroBlaze_GPIO.runs/impl_1/stopwatch_design_wrapper.mmi"
out_bit="$script_dir/260625_MicroBlaze_GPIO.runs/impl_1/stopwatch_design_wrapper_with_elf.bit"
proc_path="stopwatch_design_i/microblaze_0"

while (($#)); do
    case "$1" in
        --no-upload)
            upload=0
            shift
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        --elf)
            elf="${2:?missing value for --elf}"
            shift 2
            ;;
        --bit)
            bit="${2:?missing value for --bit}"
            shift 2
            ;;
        --mmi)
            mmi="${2:?missing value for --mmi}"
            shift 2
            ;;
        --out)
            out_bit="${2:?missing value for --out}"
            shift 2
            ;;
        --proc)
            proc_path="${2:?missing value for --proc}"
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

abs_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s/%s\n' "$PWD" "$path"
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

need_file() {
    local path="$1"
    local label="$2"
    if [[ ! -f "$path" ]]; then
        echo "Missing $label: $path" >&2
        exit 1
    fi
}

elf="$(abs_path "$elf")"
bit="$(abs_path "$bit")"
mmi="$(abs_path "$mmi")"
out_bit="$(abs_path "$out_bit")"

need_file "$elf" "Vitis ELF"
need_file "$bit" "input bitstream"
need_file "$mmi" "MMI"

if [[ -d "$script_dir/vitis_repo/StopWatch/src" ]]; then
    newer_src="$(find "$script_dir/vitis_repo/StopWatch/src" -type f \( -name '*.c' -o -name '*.h' \) -newer "$elf" -print -quit)"
    if [[ -n "$newer_src" ]]; then
        echo "Warning: source is newer than ELF. Build StopWatch in Vitis before programming if this is unexpected." >&2
        echo "Newer source: $newer_src" >&2
    fi
fi

docker_elf="$(to_docker_path "$elf")"
docker_bit="$(to_docker_path "$bit")"
docker_mmi="$(to_docker_path "$mmi")"
docker_out_bit="$(to_docker_path "$out_bit")"

echo "ELF : $elf"
echo "BIT : $bit"
echo "MMI : $mmi"
echo "OUT : $out_bit"
echo "PROC: $proc_path"

if [[ "$dry_run" -eq 1 ]]; then
    echo
    echo "Dry run:"
    echo "docker exec ... updatemem -meminfo '$docker_mmi' -data '$docker_elf' -bit '$docker_bit' -proc '$proc_path' -out '$docker_out_bit' -force"
    if [[ "$upload" -eq 1 ]]; then
        echo "openFPGALoader -b '$board' '$out_bit'"
    fi
    exit 0
fi

command -v docker >/dev/null 2>&1 || {
    echo "docker command not found" >&2
    exit 1
}

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

docker exec \
    -e U_ELF="$docker_elf" \
    -e U_BIT="$docker_bit" \
    -e U_MMI="$docker_mmi" \
    -e U_OUT="$docker_out_bit" \
    -e U_PROC="$proc_path" \
    "$container" bash -lc '
set -eo pipefail
if [[ -f /home/user/Xilinx/Vivado/2020.2/settings64.sh ]]; then
    source /home/user/Xilinx/Vivado/2020.2/settings64.sh >/dev/null 2>&1
elif [[ -f /opt/Xilinx/Vivado/2020.2/settings64.sh ]]; then
    source /opt/Xilinx/Vivado/2020.2/settings64.sh >/dev/null 2>&1
else
    echo "Vivado 2020.2 settings64.sh not found in container" >&2
    exit 1
fi

updatemem \
    -meminfo "$U_MMI" \
    -data "$U_ELF" \
    -bit "$U_BIT" \
    -proc "$U_PROC" \
    -out "$U_OUT" \
    -force
'

if [[ "$upload" -eq 0 ]]; then
    echo "Created ELF-updated bitstream: $out_bit"
    exit 0
fi

command -v openFPGALoader >/dev/null 2>&1 || {
    echo "openFPGALoader command not found" >&2
    exit 1
}

openFPGALoader -b "$board" "$out_bit"
