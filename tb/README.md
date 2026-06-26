# Testbench Layout

`tb/` keeps project-level directed testbenches.

| Folder | Role |
| --- | --- |
| `rtl/` | Standalone RTL testbenches that do not drive an AXI register interface |
| `axi/` | Directed AXI4-Lite register/interface testbenches |

Vivado IP Packager BFM example testbenches remain inside each packaged IP:

```text
ip/<ip_name>_1.0/example_designs/bfm_design/
```

Those BFM files depend on Vivado-generated include files and AXI VIP packages,
so they stay with the packaged IP instead of being duplicated under `tb/axi`.
