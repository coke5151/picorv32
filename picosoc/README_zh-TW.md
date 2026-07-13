# PicoSoC 繁體中文導覽

PicoSoC 是本 repository 最接近「真的能燒進 FPGA 跑 RISC-V code」的範例。它支援 iCEBreaker
(iCE40-UP5K) 與 iCE40-HX8K demo board，CPU 從外接 SPI Flash XIP，片上 RAM 放可寫資料與 stack。

## 模組分工

| 檔案 | 作用 |
| --- | --- |
| `picosoc.v` | PicoRV32、RAM、SPI memory controller、UART 的 address decode 與連接 |
| `icebreaker.v` | iCEBreaker top、SPRAM、pin I/O、LED GPIO |
| `hx8kdemo.v` | HX8K demo board top、LED GPIO、debug pin |
| `ice40up5k_spram.v` | 把四個 16-bit iCE40 SPRAM block 組成 byte-write 32-bit memory |
| `spimemio.v` | memory-mapped SPI/Dual/Quad/DDR Flash read controller |
| `simpleuart.v` | 最小 8N1 UART transmitter/receiver |
| `start.s` | reset 後的 C runtime 初始化與 manual SPI helper |
| `sections.lds` | Flash/RAM memory layout |
| `firmware.c` | UART command demo、Flash mode 測試、LED 操作 |
| `*.pcf` | 兩塊板各自的 pin constraint |
| `*_tb.v`、`spiflash.v` | SoC testbench 與 behavioral Flash model |
| `*.core` | FuseSoC core 描述 |

## 建置目標

在本目錄執行：

| 指令 | 結果 |
| --- | --- |
| `make icebsim` | 編譯 iCEBreaker firmware 並跑 RTL simulation |
| `make icebprog` | 建立 bitstream，並把 bitstream/firmware 寫入 Flash |
| `make icebprog_fw` | 只更新 iCEBreaker firmware |
| `make hx8ksim` | 跑 HX8K RTL simulation |
| `make hx8kprog` | 建立並燒錄 HX8K bitstream/firmware |
| `make hx8kprog_fw` | 只更新 HX8K firmware |

需要 Yosys、nextpnr-ice40、IceStorm、Icarus Verilog 與 bare-metal RISC-V GCC。實際 tool prefix 可由
Makefile 變數調整。

## 開機流程

1. FPGA configuration 完成，reset counter 等待數十個 clock。
2. PicoRV32 的 PC 設為 `0x0010_0000`。
3. `spimemio` 把該 address 轉成 Flash read，CPU 直接取出 `start.s`。
4. startup 初始化 RAM 與 stack，將 `.data` 從 Flash 搬到 RAM，清除 `.bss`。
5. 呼叫 `firmware.c` 的 `main()`，設定 UART 並顯示互動選單。

完整 memory map 與移植重點請看 [`../docs/03-picosoc-memory-map.md`](../docs/03-picosoc-memory-map.md)
和 [`../docs/07-porting-checklist.md`](../docs/07-porting-checklist.md)。原本的 `README.md` 保留上游
英文的 register bit 定義與 performance 表格，查 SPI config register 時仍很有用。
