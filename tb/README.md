# Testbench Layout

`tb/` keeps project-level directed testbenches in one flat folder.

| File pattern | Role |
| --- | --- |
| `tb_<ip>.sv` | Directed AXI4-Lite target register/interface testbench |
| `tb_rtl_<block>.sv` | Standalone RTL testbench that does not drive an AXI register interface |

Vivado IP Packager example-design templates are generated scaffolds, not
project source. They are excluded from this clean implementation repository.

Current directed AXI testbenches:

| File | Scope |
| --- | --- |
| `tb_iic.sv` | IIC AXI register write/read path with an open-drain target model |
| `tb_timer.sv` | Timer AXI register and interrupt smoke test |
| `tb_uart.sv` | UART AXI register loopback smoke test |
