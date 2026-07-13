# 模擬與除錯

## 為什麼先模擬

FPGA 上「沒有反應」可能是 RTL、firmware、constraint、clock、reset、燒錄位址或 UART baud 任一層。
模擬先排除 RTL 與 firmware，之後上板只需集中查板級問題。

## 根目錄 testbench

| 指令 | 內容 |
| --- | --- |
| `make test_ez` | 最小 Native interface 測試，不需要 RISC-V toolchain |
| `make test` | 編譯完整 test firmware，再跑標準 testbench |
| `make test_vcd` | 同上並輸出 VCD 波形 |
| `make test_axi` | 以 AXI wrapper 執行 |
| `make test_wb` | 以 Wishbone wrapper 執行 |
| `make test_verilator` | 使用 Verilator C++ harness |

Makefile 預設使用 Icarus Verilog、Yosys 和 RISC-V GCC。Windows 原生環境不一定已有這些工具；可用
WSL、OSS CAD Suite、conda 套件或各 FPGA vendor tool 提供的 shell。

## PicoSoC 模擬

在 `picosoc/`：

- `make icebsim` 模擬 iCEBreaker 版本。
- `make hx8ksim` 模擬 HX8K demo board 版本。
- `*_tb.v` 同時實例化 SoC 與 behavioral SPI Flash model，讓 CPU 真的從 Flash window 取指。
- `spiflash_tb` 單獨驗證 Flash model/controller 行為。

## 波形先看哪些訊號

建議依序加入：

1. `resetn`、`clk`：reset 是否確實解除。
2. `cpu_state`、`mem_valid`、`mem_ready`、`mem_instr`。
3. `mem_addr`、`mem_wstrb`、`mem_wdata`、`mem_rdata`。
4. `trap`：是否遇到非法指令、未對齊或 bus 不回覆。
5. `ser_tx`、GPIO register：程式是否已跑到輸出。

若 `mem_valid=1` 而 `mem_ready` 永遠是 0，問題通常在 address decode 或 target handshake。若 address
一直停在 reset vector，檢查 Flash image/offset。若 `trap=1`，反組譯該 PC 附近的 instruction。

## Trace

開啟 `ENABLE_TRACE` 後，core 會輸出 `trace_valid` 與 `trace_data`。根目錄的 `showtrace.py` 可把 trace
資料轉成人類可讀資訊。Trace 會增加硬體邏輯；若只用於模擬，可用 parameter 或 synthesis define
在 release bitstream 關閉。

## 常見錯誤對照

| 現象 | 優先檢查 |
| --- | --- |
| `make` 找不到 compiler | `TOOLCHAIN_PREFIX`、PATH、是否安裝 bare-metal RISC-V GCC |
| CPU 一解除 reset 就 trap | `-march` 與 core parameter、reset vector 的內容 |
| load/store 永遠等待 | `mem_ready` 產生條件、address decode、clock domain |
| UART 亂碼 | FPGA clock 頻率、divider、terminal baud/8N1 |
| 模擬正常但 LED 不亮 | PCF/XDC/QSF pin、active-low、I/O voltage |
| synthesis 後 RAM 用大量 LUT | RAM coding style/primitive wrapper 不符合目標 FPGA |
