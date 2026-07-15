# PicoRV32 繁體中文學習導覽

這個資料夾不是逐字翻譯原始 README，而是給「想把 PicoRV32 放進 FPGA，最後跑自己 C/Assembly
程式」的實作導覽。第一次閱讀時，不需要先看完三千多行的 `picorv32.v`。

## 建議閱讀順序

1. [專案全貌](01-project-overview.md)：先認識 CPU core、SoC、firmware、testbench 各自負責什麼。
2. [CPU 核心導讀](02-cpu-core.md)：理解參數、狀態機、Native Memory Interface、PCPI。
3. [PicoSoC 與記憶體配置](03-picosoc-memory-map.md)：追一次 CPU load/store 如何到 RAM、Flash、UART、GPIO。
4. [Firmware 從編譯到執行](04-firmware-flow.md)：理解 startup code、linker script、ELF/HEX/BIN。
5. [模擬與除錯](05-simulation-and-debug.md)：先在模擬器證明硬體和程式正確，再燒板。
6. [FPGA 實作流程](06-fpga-bringup.md)：時脈、reset、pin constraint、合成、place-and-route、燒錄。
7. [移植到自己的板子](07-porting-checklist.md)：逐項替換板級 top module，避免常見硬體問題。
8. [RTL 模組完整索引](08-rtl-module-reference.md)：逐一查 41 個 Verilog 檔、61 個 module 的用途與邊界。
9. [軟體與工具鏈索引](09-source-and-tooling-reference.md)：串起 firmware、linker、測試與各 EDA script。

## 最短實作路線

```text
自己的 C/Assembly
      │ RISC-V GCC + linker script
      ▼
 firmware.elf ── objcopy/轉檔 ──► firmware.bin 或 firmware.hex
                                      │
                                      ▼
板級 top ─► PicoSoC ─► PicoRV32 ─► RAM / SPI Flash / UART / GPIO
   │
   └── constraint + synthesis + place-and-route ──► bitstream ──► FPGA
```

如果只是想先看到 CPU 跑起來：

- 沒有 RISC-V compiler 時，可先執行根目錄的 `make test_ez`。
- 使用原生 memory interface 的完整測試，可執行 `make test`（需要 toolchain）。
- 使用 iCEBreaker 或 iCE40-HX8K demo board，可從 `picosoc/Makefile` 的 `icebsim`、`icebprog`、
  `hx8ksim`、`hx8kprog` 開始。

## 名詞速查

| 名詞 | 這個專案裡的意思 |
| --- | --- |
| Core | 只包含 CPU，不自帶一般用途 RAM、UART 或 GPIO |
| SoC | CPU 加上 memory、interconnect、peripheral 的完整小系統 |
| RTL | 用 Verilog 描述的暫存器與組合邏輯 |
| Native Memory Interface | PicoRV32 自訂的簡單 valid/ready 記憶體介面 |
| MMIO | 用一般 load/store 存取 peripheral register |
| PCPI | PicoRV32 的外接 co-processor 介面，內建乘除法也走這條路 |
| XIP | Execute In Place，CPU 直接從 SPI Flash 取指，不先整份搬到 RAM |
| Constraint | FPGA 腳位、I/O standard、clock timing 等限制檔 |

## 閱讀原始碼的方法

先從 module 的輸入輸出和「資料往哪裡走」看起，再看 always block。對 `picorv32.v` 建議依序搜尋：

1. `module picorv32`：參數和外部介面。
2. `mem_state`：記憶體交易控制。
3. `instr_lui` 等 `instr_*`：指令解碼結果。
4. `cpu_state_fetch`：CPU 主狀態機。
5. `picorv32_pcpi_mul` / `picorv32_pcpi_div`：可選乘除法單元。
6. `picorv32_axi` / `picorv32_wb`：不同匯流排包裝。

不要只看訊號名稱猜行為；把波形裡的 `mem_valid`、`mem_ready`、`mem_addr`、`mem_wstrb`
放在一起看，通常最快。

若遇到多個都叫 `testbench`、`top` 或 `system` 的模組，請一定連同路徑一起辨識；它們是不同、彼此
獨立的建置情境，不應同時編入同一個 design。完整對照見
[RTL 模組完整索引](08-rtl-module-reference.md)。
