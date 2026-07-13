# FPGA 實作流程

## 一次完整建置包含什麼

```text
Verilog RTL + constraint
        │ synthesis
        ▼
 technology netlist
        │ place and route + timing
        ▼
 bitstream ── programmer ──► FPGA configuration memory

C/Assembly + linker script ──► firmware image ──► block RAM init 或 external Flash
```

硬體 bitstream 和 firmware 是兩條建置鏈。PicoSoC 範例把 SoC bitstream 與 firmware 分別放進 SPI
Flash 不同 offset；若改成 block RAM boot，firmware 內容可能在 synthesis 時就包進 bitstream。

## 先盤點你的 FPGA 板

開始移植前確認：

- FPGA vendor、family、精確 part number。
- oscillator 頻率，以及是否需要 PLL。
- 可用 block RAM/embedded RAM 大小。
- 外接 SPI/QSPI Flash 型號、容量、接線和 FPGA configuration 共用限制。
- USB-UART 的 TX/RX pin、電壓、baud。
- LED 是否 active-low。
- programmer 與 bitstream 格式。

這些資料應以原理圖與官方 reference design 為準，不能只靠相似板名猜測。

## iCE40 範例流程

`picosoc/Makefile` 使用開源 iCE40 flow：

1. Yosys：Verilog synthesis 成 JSON netlist。
2. nextpnr-ice40：依 PCF 放置繞線，產生 ASC。
3. icepack：ASC 轉 bitstream BIN。
4. iceprog：燒錄 FPGA/Flash。

`icebreaker.pcf` 與 `hx8kdemo.pcf` 只適用對應原廠板。換板一定要重做 constraint，不能直接燒錄。

## Clock 與 timing

UART divider、SPI timing 和所有 cycle-based delay 都依賴實際 clock。constraint 也必須宣告正確 clock
period，否則 place-and-route 顯示成功不代表硬體能在該頻率工作。先用板上原生 oscillator 的保守
頻率 bring-up，再考慮 PLL 與提高 Fmax。

## Reset

範例使用 6-bit counter 產生 power-on reset，假設 FPGA register 可初始化為 0。換到不同 family 時
要確認：

- initial value 是否能合成並由 configuration 設定。
- 外部 reset button 的極性與 debounce。
- PLL lock 前是否應保持 reset。
- 所有 peripheral 是否使用同一個同步解除的 reset。

非同步 assert、同步 deassert 是更通用的 reset 策略，但要依你的 clock 架構實作。

## RAM 選擇

CPU core 的 register file、scratchpad RAM 和 firmware storage 是三件不同的事。綜合報告要確認它們
映射到預期資源：block RAM、distributed RAM、SPRAM 或 LUT/flip-flop。若容量超過片上 RAM，可
XIP 或加 SDRAM controller，但後者會明顯增加專題複雜度。

## 最小上板驗收順序

1. 只做 clock divider 驅動 LED，驗證 bitstream 與 pin。
2. 加 reset counter，讓 LED 顯示 reset 狀態。
3. 加 PicoRV32 + block RAM，跑無 peripheral 的小 assembly loop。
4. 加 GPIO MMIO，跑 LED counter。
5. 加 UART，印固定 banner。
6. 最後才加 SPI Flash XIP、interrupt 和自己的 accelerator。

每一步保留一個可回退的版本，發生問題時才知道是哪一層新增功能造成。
