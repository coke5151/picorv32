# 根目錄測試 Firmware 導覽

這裡的程式是根目錄 `testbench.v` 使用的自我測試 firmware，不是 PicoSoC 板級 demo。它會執行
RISC-V instruction tests、C 測試、IRQ 與乘法/除法測試，最後由 testbench 判定成功或失敗。

## 重要檔案

| 檔案 | 作用 |
| --- | --- |
| `start.S` | reset entry、IRQ entry、register/RAM 初始化，接著呼叫 C code 與各 ISA test |
| `sections.lds` | 決定 testbench memory 中 `.text`、`.data`、`.bss`、stack 的位置 |
| `firmware.h` | 測試 firmware 共用宣告與 MMIO 定義 |
| `irq.c` | 測試 PicoRV32 自訂 IRQ、timer 與 fault handling |
| `custom_ops.S` | 封裝 PicoRV32 IRQ custom instruction |
| `hello.c` | 基本輸出與簡單 C 程式入口 |
| `multest.c` | 乘法結果測試 |
| `sieve.c` | 質數篩選，測試一般 C code 與 memory access |
| `stats.c` | cycle/instruction counter 統計 |
| `print.c` | testbench console 輸出函式 |
| `makehex.py` | binary 轉成 Verilog `$readmemh` 使用的文字格式 |

## 建置關係

根目錄 Makefile 會把 `firmware/*.c`、`firmware/start.S` 與 `tests/*.S` 編譯成 object，再連結成
`firmware.elf`，最後產生 `firmware.bin` 和 `firmware.hex`。若只想開發 FPGA 板上的應用，請先看
[`picosoc/README_zh-TW.md`](../picosoc/README_zh-TW.md)，不要直接把這套 test firmware 當產品程式。

## 修改時注意

- `-march` 必須符合 testbench 實例化的 core parameter。
- testbench 使用特殊 MMIO address 收集字元、結束狀態與測試結果；這些 address 不一定存在於 FPGA。
- `firmware/README` 是上游留下的簡短英文說明，本檔補充繁中學習導覽。
