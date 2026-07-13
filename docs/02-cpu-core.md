# PicoRV32 CPU 核心導讀

## Core 能做什麼

`picorv32` 是小面積、以多週期狀態機實作的 in-order CPU。它不是五級 pipeline 教材型架構；一條
指令可能依序經過 fetch、讀 register、execute、memory 等狀態。這讓控制邏輯和面積較小，也使
外部 memory wait state 很容易處理。

## 最重要的參數

| 參數 | 影響 | 初次實作建議 |
| --- | --- | --- |
| `ENABLE_MUL` | 加入迭代式乘法 PCPI | 需要 RV32M 時開啟 |
| `ENABLE_FAST_MUL` | 使用較快、較耗 DSP/LUT 的乘法器 | 依 FPGA 資源決定，勿和 `ENABLE_MUL` 同開 |
| `ENABLE_DIV` | 加入除法/餘數 PCPI | 軟體會用除法時開啟 |
| `COMPRESSED_ISA` | 支援 16-bit RVC 指令 | toolchain 用 `rv32ic/imc` 時開啟 |
| `BARREL_SHIFTER` | shift 可較少 cycle 完成，但面積增加 | 資源足夠可開 |
| `ENABLE_COUNTERS` | `rdcycle`、`rdinstret` 等 counter | firmware 有使用時必須開 |
| `ENABLE_IRQ` | 啟用 PicoRV32 自訂 IRQ 機制 | PicoSoC 預設開啟 |
| `CATCH_MISALIGN` | 未對齊存取進入 trap | 建議保持開啟 |
| `CATCH_ILLINSN` | 非法指令進入 trap | 建議保持開啟 |
| `PROGADDR_RESET` | reset 後第一個取指位址 | 必須符合 linker script |
| `STACKADDR` | reset 時 x2 (`sp`) 初值 | 通常設成 RAM 尾端 |

CPU 設定和 compiler 的 `-march` 必須一致。例如硬體沒開 `COMPRESSED_ISA`，firmware 就不能用
`-march=rv32imc` 產生 compressed instruction。

## 主狀態機

`cpu_state` 使用 one-hot 編碼，主要狀態為：

```text
fetch ─► ld_rs1 ─► ld_rs2 ─► exec ─► fetch
  │          │          │       ├──► shift ─► fetch
  │          │          │       ├──► stmem ─► fetch
  │          │          │       └──► ldmem ─► fetch
  └──────────────────────────────► trap（錯誤且無法處理）
```

實際路徑依指令而異。例如 `LUI` 不必讀兩個 operand，load/store 才會進 memory state。程式裡大量
`latched_*` 訊號用來把 decode/execute 的決定保存到後續 cycle。

## 指令解碼

取回的 instruction 先被拆成 opcode、register index 和 immediate，再產生 `instr_add`、
`instr_lw`、`instr_jal` 等 one-hot 類型訊號。核心也支援 RVC，所以取指邏輯會處理一個 32-bit
word 裡的兩個 16-bit instruction，以及跨 word 的 32-bit instruction。

## Register file

預設可用 x0～x31，其中 x0 永遠讀出 0。`ENABLE_REGS_16_31=0` 可縮成 RV32E。register file 可用
內建 array，也能透過 `PICORV32_REGS` macro 替換成適合特定 FPGA/ASIC memory primitive 的版本。
PicoSoC 就用 `picosoc_regs` 替換它。

## PCPI

PCPI（Pico Co-Processor Interface）把無法由基本 ALU 執行的指令交給外部單元：

1. CPU 拉高 `pcpi_valid`，送出 instruction、rs1、rs2。
2. co-processor 可用 `pcpi_wait` 表示還在計算。
3. 完成時拉高 `pcpi_ready`；若要寫回 rd，也拉高 `pcpi_wr` 並提供 `pcpi_rd`。
4. 沒有單元接受指令且 timeout 時，CPU 把它當 illegal instruction。

內建 `picorv32_pcpi_mul`、`picorv32_pcpi_fast_mul`、`picorv32_pcpi_div` 也是接到同一套介面。

## IRQ 注意事項

PicoRV32 IRQ 是專案自訂的輕量機制，不是完整 RISC-V privileged architecture/PLIC/CLINT。它使用
`getq`、`setq`、`retirq`、`maskirq`、`waitirq`、`timer` 等 custom instruction。若專題需要跑
Linux、標準 machine-mode trap 或現成 RTOS port，必須先確認軟體是否支援這套機制。

## AXI 與 Wishbone wrapper

`picorv32_axi_adapter` 把一次 Native Memory transaction 拆成 AXI read/write channel handshake。
`picorv32_wb` 則產生 `wbm_cyc_o`、`wbm_stb_o`，等待 `wbm_ack_i`。wrapper 不會替你處理 address
decode；RAM 和 peripheral 仍要由外部 SoC/interconnect 提供。
