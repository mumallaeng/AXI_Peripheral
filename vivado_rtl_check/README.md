# Vivado RTL Check Projects

This folder contains lightweight Vivado 2020.2 projects for opening and checking
individual packaged IP RTL without loading the full MicroBlaze block design.

| Project | Top module | Source scope |
| --- | --- | --- |
| `gpio_rtl_check.xpr` | `gpio_v1_0` | `ip/gpio_1.0/hdl` |
| `timer_rtl_check.xpr` | `timer_v1_0` | `ip/timer_1.0/hdl` |
| `uart_rtl_check.xpr` | `uart_v1_0` | `ip/uart_1.0/hdl` |
| `spi_rtl_check.xpr` | `spi_v1_0` | `ip/spi_1.0/hdl` |
| `iic_rtl_check.xpr` | `iic_v1_0` | `ip/iic_1.0/hdl` |

Create the full system block design with `scripts/vivado/create_project.tcl`.
