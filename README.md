# AXI Peripheral

AXI4-Lite peripheral, custom IP, MicroBlaze integration, and Vitis firmware practice repository.

## Layout

| Path | Purpose |
| :--- | :--- |
| `projects/` | Date-based runnable Vivado/Vitis project snapshots. Keep block design integration, `.xpr`, `.srcs`, testbench, XDC, and matching `vitis_repo` together when they are coupled. |
| `ip/` | Reusable packaged IP sources. Keep `component.xml`, `hdl/`, `drivers/`, `xgui/`, and example design files together for each IP. |
| `apps/` | Firmware or application code extracted from Vitis projects when it becomes reusable outside one project snapshot. |
| `boards/` | Board-level reusable constraints and board notes, such as a clean Basys-3 XDC copy. |
| `scripts/` | Build, export, bitstream update, programming, and project maintenance scripts that are reusable across projects. |
| `docs/notes/` | Imported class notes that explain the project state and design decisions. |

## Organization Rule

Use `projects/` for an executable class-day snapshot first. Extract to `ip/`, `apps/`, `boards/`, or `scripts/` only when the file is intended to be reused by more than one project.

This keeps these concerns separate:

| Concern | Home |
| :--- | :--- |
| Direct RTL module or IP implementation | `ip/<ip_name>/hdl/` or a project-local RTL path |
| Packaged custom IP | `ip/<ip_name>/` |
| Block design / MicroBlaze system integration | `projects/<date_topic>/` |
| Vitis app tied to one XSA/project | `projects/<date_topic>/vitis_repo/` |
| Reusable firmware library or app | `apps/` |
| Common board constraints | `boards/` |

## Imported History

The initial repository commit is followed by selected Vault commits from the 260622 AXI template and MicroBlaze GPIO work through the 260625 AXI TimerCounter work. Paths were rewritten into this repository layout, so commit hashes differ from Vault, but commit order, messages, authors, dates, and per-commit content changes were preserved.
