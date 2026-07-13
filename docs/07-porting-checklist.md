# 移植到自己的 FPGA 板

## 你通常要新增或修改的檔案

| 類型 | 工作 |
| --- | --- |
| `myboard.v` | 板級 top、clock/reset、I/O buffer、PicoSoC instance、GPIO |
| `myboard.pcf/xdc/qsf` | pin、I/O standard、clock timing |
| RAM wrapper | 對應目標 FPGA 的 block RAM/embedded RAM |
| build script/project | 選 part、加入 source、synthesis、place-and-route、bitstream |
| linker script | Flash/RAM origin 與容量 |
| startup code | stack、data/bss 初始化、boot 方式 |
| firmware | UART divider、MMIO address、板級功能 |

## 選擇 boot 架構

### Block RAM boot

優點是最容易模擬與 bring-up，不需要 Flash controller；缺點是 firmware 容量小，更新程式通常要
重做 bitstream。把 `PROGADDR_RESET` 設到 RAM 起點，linker `.text` 也放同一位址，並在 synthesis
前用 HEX 初始化 RAM。

### SPI Flash XIP

優點是容量大、firmware 可與 FPGA bitstream 分開更新；缺點是取指慢，且 Flash mode、dummy cycle、
共用 configuration pin 都可能出問題。可沿用 PicoSoC `spimemio`，但先核對 Flash datasheet。

### Boot ROM 搬移

小型 ROM 先執行 bootloader，把 Flash/UART 收到的 firmware 搬到 RAM 再跳轉。執行較快，但要自己
管理 image format、完整性與更新流程。

## 移植檢查表

- [ ] `PROGADDR_RESET` 等於 firmware 第一條指令的 link address。
- [ ] `STACKADDR` 位於有效 RAM 尾端並保持 ABI 對齊。
- [ ] `MEM_WORDS * 4` 與實際 RAM bytes 相符。
- [ ] compiler `-march` 沒有使用未啟用 instruction extension。
- [ ] 所有 MMIO address 不重疊，且 hardware/firmware 定義一致。
- [ ] 每個 memory target 都正確完成 valid/ready handshake。
- [ ] read data 在 `mem_ready` 有效時已穩定。
- [ ] byte/halfword write 正確處理 `mem_wstrb`。
- [ ] oscillator 頻率與 timing constraint、UART divider 一致。
- [ ] TX 接到 USB-UART RX，RX 接到 TX，並且共地。
- [ ] active-low LED/CS/reset 的極性正確。
- [ ] synthesis 報告中的 RAM/DSP/LUT 使用量合理。
- [ ] static timing analysis 沒有 unconstrained clock 或 failing path。
- [ ] bitstream 和 firmware 各自燒在正確裝置與 offset。

## 加自己的硬體加速器

一般控制/status/data register 適合做 MMIO peripheral；單次指令輸入兩個 operand、輸出一個結果，
且不會改變控制流程的運算可考慮 PCPI。大量 streaming data 通常需要 DMA/FIFO，不適合讓 CPU 用
每個 word 的 blocking load/store 搬運。

## 專題交付建議

除了 source code，保留以下可重現資訊：FPGA part、tool 版本、完整 build command、constraint、
firmware compiler 版本與 flags、memory map、UART 設定、資源用量、Fmax，以及一份從 clean checkout
到燒錄成功的步驟。這些通常比只留下 bitstream 更有價值。
