# openTPU ZU11EG

This repository groups the ZU11EG project by development environment:

- `zu11eg_openTPU_vivado/` — FPGA RTL, board constraints, Vivado 2025.2 project and scripts, and simulation testbenches.
- `zu11eg_openTPU_vitis/` — reserved for the Vitis application project; contents will be added later.
- `zu11eg_openTPU_linux/` — reserved for Linux/PetaLinux and driver sources; contents will be added later.

The Vivado source snapshot intentionally excludes generated implementation output such as bitstreams, routed checkpoints, run caches, and logs. See `zu11eg_openTPU_vivado/BUILD.md` for the project layout and build instructions.

## License

Project-authored files are licensed under Apache-2.0; see LICENSE. Third-party notices and vendor IP terms are described in THIRD_PARTY.md.