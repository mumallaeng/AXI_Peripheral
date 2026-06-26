# Testbench Layout

`tb/` keeps project-level directed testbenches in one flat folder.

| File pattern | Role |
| --- | --- |
| `tb_<ip>.sv` | Directed AXI4-Lite register/interface testbench |
| `tb_rtl_<block>.sv` | Standalone RTL testbench that does not drive an AXI register interface |

Vivado IP Packager BFM example testbenches remain inside each packaged IP:

```text
ip/<ip_name>_1.0/example_designs/bfm_design/
```

Those BFM files depend on Vivado-generated include files and AXI VIP packages,
so they stay with the packaged IP instead of being duplicated under `tb/`.
