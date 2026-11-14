# ZU11EG openTPU — Vivado 2025.2 工程（纯 FPGA 侧，可编译）

源工程：`ubuntu-peta:/workspace/openTPU_pmp0_20261112`
拉取：2026-11-14
对应板上运行 bit：`dffe2d7eab001e08f52546a9a3b1720207350cca93acb3b736253d2662857cce`（PMP=0）

**本包只含 Vivado 侧**：RTL + 约束 + Vivado 脚本 + BD/XCI/XPR + 仿真 tb。
**不含** Vitis 裸机、Linux 驱动、PetaLinux 配方、板端 Python —— 那三块分别在
`../zu11eg_openTPU_vitis/` 和 `../zu11eg_openTPU_linux/`。

也不含任何编译产物（`.bit` `.dcp` `.runs` `.gen` `.cache` `*.log` `*.jou`，约 1.6 GB 已剔除）。

---

## 1. 目录

```
zu11eg_openTPU_vivado/
├── rtl/                                   # 35 个 RTL（34 个来自 create 脚本权威清单 + block_ab 变体）
│   ├── vpu/ mem/ seq/ mxu/ dma/ shell/ tech/generic/ exp/tmem_nocopy/ top/
│   ├── zu11eg/                            # axil_join / native_fifo / native_axi_ch / native_axi_sys / dci_reset
│   └── boards/mlk-cm07-zu11eg/            # fabric.sv (PMP=0) + fabric_v.v (BD 包装) + fabric_block_ab.sv
├── targets/mlk-cm07-zu11eg.toml            # arch/uarch 参数
├── boards/mlk-cm07-zu11eg/
│   ├── constraints/                       # 6 个：ddr4_mig.pins.xdc, first_board.xdc,
│   │                                      #        otpu_clk2x.tcl(+xdc), cdc_waivers.tcl, report_timing_probe.tcl
│   ├── vivado/                            # 20 个 TCL + minimal_license_synth.v
│   ├── README.md / HARDWARE_HANDOFF.md    # 板级 DDR/PS 事实与交接状态
├── sim/vivado/                            # 5 个 tb（xsim 脚本引用）
└── vivado/first_board_pmp0_20261112/project/
    ├── opentpu_zu11eg.xpr                  # Vivado 2025.2 工程
    └── opentpu_zu11eg.srcs/                # system.bd + 38 个 .xci + system_wrapper.v
```

---

## 2. 从零重建（最干净）

```bash
export OTPU_ROOT=/root/temp/zu11eg_openTPU_vivado
cd $OTPU_ROOT

# 2.1 建工程 + 建 BD + 打包 wrapper + 挂约束（5-10 分钟）
/opt/Xilinx/2025.2/Vivado/bin/vivado -mode batch \
  -source boards/mlk-cm07-zu11eg/vivado/create_first_board_2025.tcl \
  -tclargs /root/temp/build_zu11eg
# 期望最后一行：FIRST_BOARD_BD_OK

# 2.2 综合 + 实现 + 出 bit（jobs=2，32GiB 主机不要调高，会 OOM）
/opt/Xilinx/2025.2/Vivado/bin/vivado -mode batch \
  -source boards/mlk-cm07-zu11eg/vivado/build_first_board_2025.tcl \
  -tclargs /root/temp/build_zu11eg/project/opentpu_zu11eg.xpr 2
# 期望：bit 生成成功，WNS/WHS/WPWS 全正，DRC 0 error
```

`create_first_board_2025.tcl` 自建 BD、`validate_bd_design`、`make_wrapper`，地址分配：
`0xA000_0000` ctrl / `0xA001_0000` H2C CDMA / `0xA002_0000` C2H CDMA /
`0xA003_0000` UARTLite / `0xA004_0000` INTC，PL host aperture `0x8_0000_0000`。

---

## 3. 直接开已带的 XPR（省掉建 BD）

```bash
cd $OTPU_ROOT/vivado/first_board_pmp0_20261112/project
/opt/Xilinx/2025.2/Vivado/bin/vivado opentpu_zu11eg.xpr
```

⚠️ **目录层级不能动**。XPR 里所有源都是 `$PPRDIR/../../../rtl/...` 相对引用，
`$PPRDIR/../../../rtl/top` 同时是 include_dir。把 `project/` 单独挪走会全断链。

编译：
```bash
vivado -mode batch -source $OTPU_ROOT/boards/mlk-cm07-zu11eg/vivado/build_first_board_2025.tcl \
  -tclargs $OTPU_ROOT/vivado/first_board_pmp0_20261112/project/opentpu_zu11eg.xpr 2
```

---

## 4. 关键参数（改之前先看）

| 项 | 值 |
|---|---|
| part | `xczu11eg-ffvc1760-2-i` |
| Core clock | 100 MHz（`ps pl_clk0`，IOPLL） |
| TMEM pump clock | 200 MHz，**由 clk_wiz_0 从 pl_clk0 生成**（不是 PS PL1） |
| `TMEM_PMP` | **0**（板上运行值；=1 是 URAM 版，见 §5） |
| `TMEM_IMPL/NSB/TDP/GST/RPL` | 3 / 2 / 1 / 1 / 1 |
| `TMEM_WORDS` | 65536 |
| `D / MCOLS / ACT_ROWS / LANES` | 128 / 4 / 16 / 8 |
| Host 接口 | PS `M_AXI_HPM0`(128bit) → ctrl_ic；2× AXI CDMA 128bit；PL host aperture `0x8_0000_0000` |
| DDR | 2 × DDR4-2400 MIG（64bit / 512bit AXI / 300MHz UI / MT40A512M16HA-083E） |
| 资源占用（PMP=0） | CLB 35,602/37,320 = 95.40%；BRAM 512.5/600 = 85.42%；**URAM 0/80**；LUT 197,201 = 66.05%；DSP 217/2,928 = 7.41% |
| 时序（PMP=0） | WNS +0.003 / WHS +0.010 / WPWS +0.032 ns |

### PMP=1（URAM 版）怎么切
`rtl/boards/mlk-cm07-zu11eg/otpu_zu11eg_fabric.sv` 第 443 行：
```verilog
.TMEM_TDP(1'b1), .TMEM_GST(1'b1), .TMEM_PMP(1),   // ← 0 改 1
```
资源随之变为 **BRAM 448.5/74.75%、URAM 64/80、CLB 93.56%**（省 64 个 RAMB36）。
代价：已知 URAM 端口 A 读相位 bug（VPU MUL/ADD/COPY 全错），且本包未做 PMP=1 的编译验证。

---

## 5. A/B 与调试变体脚本

| 脚本 | 用途 |
|---|---|
| `create_first_board_block_ab_2025.tcl` | 建 BRAM A/B 对照工程 |
| `create_first_board_ila_ab_2025.tcl` | 建带 ILA 工程（`otpu_slice_ila_ab.sv`，TMEM MXU/VPU lane-0 探针） |
| `insert_otpu_ila.tcl` | 在已有工程插 ILA |
| `report_first_board_placed_2025.tcl` | 层级利用率 + 时序报告 |
| `reroute_d_bitslice_2025.tcl` | 修 MIG `RXTX_BITSLICE` byte10 WPWS（AMD 已知问题） |
| `route_explore_first_board_2025.tcl` / `route_retry_first_board_2025.tcl` | 布线失败重试 |
| `postroute_opt_first_board_2025.tcl` | 布线后时序优化 |
| `export_final_xsa_2025.tcl` | 导出 XSA（给 PetaLinux 用） |
| `minimal_license_synth.tcl` + `.v` | 最小 license 自检（确认 ZU11EG 综合授权） |

---

## 6. 仿真

```bash
vivado -mode batch -source boards/mlk-cm07-zu11eg/vivado/run_xsim_fabric_smoke_2025.tcl
vivado -mode batch -source boards/mlk-cm07-zu11eg/vivado/run_xsim_native_axi_dual_2025.tcl
vivado -mode batch -source boards/mlk-cm07-zu11eg/vivado/run_xsim_native_fifo_xpm_2025.tcl
```
这些脚本引 `$tool_bin/../../../data/verilog/src/glbl.v`（Vivado 自带），无需额外文件。

---

## 7. 明确不含（按需再取）

| 项 | 远端位置 |
|---|---|
| `system.bit` / `routed.dcp` / XSA | `.../vivado/first_board_pmp0_20261112/project/opentpu_zu11eg.runs/impl_1/` |
| 利用率/时序/DRC/CDC 报告 | `.../project/reports/`（已另存 IMA `evidence/zu11eg-pmp0-util-20261112/`） |
| `otpu_slice_ila_ab.sv` | `.../rtl/top/otpu_slice_ila_ab.sv` |
| 其余板卡 RTL（K7/BCU1525/ASIC） | `.../rtl/boards/{ypcb-00338,bcu1525}/`、`rtl/asic/`、`rtl/exp/{tz,seq_vpu}/` |
| Vitis 裸机 | → `../zu11eg_openTPU_vitis/` |
| Linux 驱动 / PetaLinux / 板端 Python | → `../zu11eg_openTPU_linux/` |

---

## 8. 校验

```bash
cd $OTPU_ROOT && find . -type f | wc -l    # 114
du -sh .                                   # 4.8 MB
```
