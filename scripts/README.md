# scripts 目錄導覽

這裡集合多種 synthesis、simulation、formal verification 與壓力測試範例。它們彼此獨立，不需要
全部跑過才能把 PicoRV32 放上 FPGA。

| 子目錄 | 用途 | 何時閱讀 |
| --- | --- | --- |
| `icestorm/` | 最小 iCE40 SoC、firmware 與開源建置流程 | 想看比 PicoSoC 更小的 FPGA 範例 |
| `vivado/` | Xilinx Vivado 面積、速度與 system synthesis 範例 | 目標是 Xilinx FPGA |
| `quartus/` | Intel Quartus 面積、速度與 system synthesis 範例 | 目標是 Intel FPGA |
| `yosys/` | Yosys synthesis script 與 cell library 範例 | 研究 generic synthesis |
| `presyn/` | 先 synthesis 再模擬的範例 | 比較 RTL 與 gate-level 行為 |
| `romload/` | ROM boot / 載入程式範例 | 想改成片上 ROM/RAM 開機 |
| `cxxdemo/` | bare-metal C++ firmware | 需要 constructor 或 C++ runtime 範例 |
| `smtbmc/` | SymbiYosys/Yosys SMT formal check | 做 formal verification |
| `csmith/` | Csmith random C program 測試 | 壓力測 CPU/compiler 一致性 |
| `torture/` | riscv-torture 隨機 ISA 測試 | 大量隨機 instruction 驗證 |
| `tomthumbtg/` | 第三方 random instruction generator 流程 | 補充隨機測試 |
| `yosys-cmp/` | 比較 Yosys、Vivado、Synplify synthesis | 做工具/面積研究 |

## FPGA 專題如何選

先依 FPGA vendor 看 `vivado/`、`quartus/` 或 `icestorm/`，但這些多半是 tool flow 範例，不一定
包含你的板級 pin 與 peripheral。完整可跑 UART/Flash/LED 的參考仍以 `picosoc/` 為主，再把其 SoC
結構搬進對應 vendor project。

不要直接使用別塊板子的 PCF/XDC/QSF；即使 FPGA part 相同，pin 和電壓也可能不同。

每個 Verilog `testbench`／`top` 的實際證明或量測目的，請查
[`../docs/08-rtl-module-reference.md`](../docs/08-rtl-module-reference.md)；各子目錄的輸入、產物與外部
依賴則整理在 [`../docs/09-source-and-tooling-reference.md`](../docs/09-source-and-tooling-reference.md)。
