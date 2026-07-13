# 專案全貌

## 這個 repository 是什麼

PicoRV32 是可合成（synthesizable）的 32-bit RISC-V CPU core。它實作 RV32I，並可選擇加入 M
（乘除法）與 C（compressed instruction）extension。它不是像 MCU 一樣固定配好 Flash、RAM、UART
和 GPIO；你可以只拿 `picorv32.v`，自行接進任何 SoC。

這份 repository 同時放了幾種不同層級的內容：

| 路徑 | 角色 | 初學時的優先度 |
| --- | --- | --- |
| `picorv32.v` | CPU core、乘除法 PCPI、AXI/Wishbone wrapper | 高 |
| `picosoc/` | 可在兩塊 iCE40 FPGA 板執行的完整 SoC | 最高 |
| `firmware/` | 根目錄 testbench 使用的 CPU/IRQ/指令測試程式 | 中 |
| `tests/` | 從 riscv-tests 衍生的單一指令測試 | 中 |
| `testbench*.v` | Native、AXI、Wishbone 介面的模擬平台 | 高 |
| `dhrystone/` | Dhrystone benchmark | 低，功能正確後再看 |
| `scripts/` | 各種 FPGA/EDA tool、formal、random test 範例 | 依需求 |
| `picorv32.core` | FuseSoC core 描述檔 | 使用 FuseSoC 時才需要 |

## 三種 CPU 外部介面

`picorv32.v` 內包含三個可直接實例化的 CPU 版本：

- `picorv32`：原生 valid/ready memory interface。邏輯少，最適合小型自製 SoC。
- `picorv32_axi`：外部是 AXI4-Lite master，適合接現有 AXI interconnect/IP。
- `picorv32_wb`：外部是 Wishbone master，適合 LiteX、Wishbone peripheral 等環境。

三者用的是同一個 CPU 執行核心。AXI 與 Wishbone 版本只是加上 protocol adapter；選擇時應看你的
SoC 已經使用哪種 bus，而不是看 CPU 指令功能。

## PicoSoC 的硬體層級

```text
icebreaker.v / hx8kdemo.v       板級 top：pin、reset、GPIO、FPGA primitive
             │
             └── picosoc.v      address decode 與元件連接
                   ├── picorv32 CPU
                   ├── picosoc_mem / FPGA SRAM
                   ├── spimemio SPI Flash XIP controller
                   └── simpleuart UART
```

板級 top 的檔名和 constraint 必須配合實際 FPGA 板。`picosoc.v` 大多可重用；若你的板沒有外接
SPI Flash，也可以拿掉 `spimemio`，改成從 block RAM 開機。

## 軟體層級

CPU reset 後只知道 reset vector，並不知道 C runtime。`picosoc/start.s` 先初始化 register、RAM、
`.data`、`.bss` 和 stack，再呼叫 `main()`。`picosoc/sections.lds` 決定每段程式應放在 Flash 還是
RAM。`picosoc/firmware.c` 用 `volatile` pointer 存取 UART、SPI controller 和 LED GPIO。

## 哪些內容不是一般 FPGA 專題的必要項目

- `scripts/smtbmc/` 是 formal verification，不影響一般 bitstream 建置。
- `scripts/csmith/`、`scripts/torture/` 是隨機程式/ISA 壓力測試。
- `scripts/yosys-cmp/` 比較不同 synthesis tool 的結果。
- `scripts/presyn/`、`scripts/vivado/`、`scripts/quartus/` 主要是評估 core 或示範簡單 system，
  不等同於 PicoSoC 的 iCE40 板級設計。

專題初期先讓 UART 印出字串與 LED 閃爍，再逐步加入自己的 peripheral，會比一開始研究全部驗證
腳本有效率。
