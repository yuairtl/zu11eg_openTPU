# ZU11EG hardware handoff

Status: `SOURCE-AUDIT-COMPLETE / DYNAMIC-VERIFICATION-PENDING`

> **Do not use the artifact names or hashes below for board bring-up.** They were
> generated before the latest address-mask, DMA-mask, calibration and AXI-skid
> fixes. A new bitstream, XSA, PetaLinux image and driver build are required;
> the previous bundle is retained only as historical evidence.

## Previous artifacts (historical only)

The previous bundle on the Ubuntu VM was:

```text
/workspace/openTPU/build/board_bundle_final_20251031
```

Important files:

The old bundle's `SHA256SUMS` is not a release manifest for the corrected source.

## Previous build gates (not valid for the corrected source)

- Part: `XCZU11EG-FFVC1760-2-i`
- Timing: WNS `+0.009 ns`, WHS `+0.010 ns`, WPWS `+0.039 ns`
- Timing failing endpoints: `0`
- Route errors: `0`
- DRC errors: `0`
- Final XSA embedded bit hash equals the standalone `system.bit`
- PetaLinux 2025.2: FSBL, PMUFW, ATF, U-Boot, Linux 6.12.40, DTB and initrd rootfs built
- Rootfs: Python 3.12, NumPy 1.26.4, `/dev/otpu0` module and modules-load entry present
- Bootgen parses `BOOT.BIN` successfully; its PL partition is the final bitstream

## Remaining hardware actions

1. Finish the source review and rebuild the RTL, XSA, PetaLinux image and driver.
2. Connect board power, JTAG and the PL UART.
3. Make JTAG and UART visible to `ubuntu-peta`, or reach a `hw_server`.
4. Confirm the physical boot medium and boot-mode straps (QSPI or eMMC).
5. Program the new `BOOT.BIN` and place the new `image.ub` on the selected boot medium.
6. On the current F002 UART mapping, FPGA `M16=RX` receives CH342K `TXD1`
   (pin 5), and FPGA `M17=TX` drives CH342K `RXD1` (pin 6). Verify U-Boot and
   Linux boot at 115200 8N1. This is a first-board FPGA-side compensation for
   the reversed CH342 wiring; a PCB ECO should swap `UART_TXD_PL` and
   `UART_RXD_PL` and restore the reference R2 mapping `M17=RX`, `M16=TX`.
7. Verify `/dev/otpu0`, `otpu_zynq`, both `xilinx_dma` channels and `ttyUL0`.
8. Run:

```sh
export PYTHONPATH=/opt/opentpu
python3 /opt/opentpu/boards/mlk-cm07-zu11eg/board_bundle/board_smoke.py
```

9. Run one exported model:

```sh
python3 /opt/opentpu/boards/mlk-cm07-zu11eg/board_bundle/run_board_tokens.py \
  --model /data/models/Qwen3-0.6B \
  --image /data/models/qwen3-0.6b.img \
  --tokens 151644 872 198 3838 374 279 6722 315 9625 30
```

The VM currently has no JTAG or USB-UART device exposed. Software-side work is
complete; execution is blocked on the physical connection.
