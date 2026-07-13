# PicoSoC 與記憶體配置

## CPU memory handshake

PicoRV32 用同一組介面取 instruction 與讀寫 data：

- CPU 拉高 `mem_valid`，同時固定 `mem_addr`、`mem_wdata`、`mem_wstrb`。
- target 準備好時拉高 `mem_ready`。
- 在 `mem_valid && mem_ready` 的 clock edge 完成一次 transaction。
- read 時 `mem_wstrb == 0`，資料由 `mem_rdata` 回傳。
- write 時 `mem_wstrb[3:0]` 是四個 byte lane enable；不能只靠「非零」判斷 word write。
- `mem_instr=1` 表示這是 instruction fetch，可用於分開 instruction/data memory 或監測。

target 若來不及回覆，就保持 `mem_ready=0`；CPU 會等待，因此 RAM、SPI Flash 和慢 peripheral
可以共用同一介面。

## PicoSoC address decode

| 位址範圍 | 元件 | 說明 |
| --- | --- | --- |
| `0x0000_0000` ～ `4*MEM_WORDS-1` | scratchpad RAM | stack、`.data`、`.bss`，IRQ vector 也可放這裡 |
| RAM 結尾 ～ `0x01FF_FFFF` | SPI Flash memory window | XIP 讀取；實際 Flash address 使用低 24 bit |
| `0x0200_0000` | SPI controller config | 調整 SPI/QSPI 模式，也可切 manual transfer |
| `0x0200_0004` | UART clock divider | 每個 serial bit 使用的 clock divider |
| `0x0200_0008` | UART data | 寫入送一 byte；讀取接收 byte，無資料時回傳 `0xFFFF_FFFF` |
| `0x0300_0000` 起 | 板級 I/O | 範例 top 用高位 byte `0x03` decode 成 LED GPIO |

`picosoc.v` 把 `mem_ready` 和 `mem_rdata` 做 mux。每個 target 必須只在自己被選中時回覆；如果兩個
target 同時 ready，read data 優先順序會掩蓋設計錯誤。

## 為什麼從 `0x0010_0000` 開機

PicoSoC 的 `PROGADDR_RESET=0x0010_0000`，linker script 的 `FLASH ORIGIN` 也是同一位址。Flash 前
1 MiB 可留給 bitstream；firmware 放在 Flash offset `0x0010_0000`，CPU 透過 memory-mapped SPI
controller 直接 XIP。

這三個位置必須一起修改：

1. CPU 的 `PROGADDR_RESET`。
2. linker script 的 code origin。
3. programmer 寫入 firmware 的 Flash offset。

任一處不同，常見現象就是 reset 後完全沒有 UART 或 LED 動作。

## Scratchpad RAM

generic `picosoc_mem` 是 32-bit word array，每個 byte 可獨立寫入。同步 read 會在下一個 clock 回傳，
所以 `ram_ready` 也延遲一個 cycle。iCEBreaker top 用 `ice40up5k_spram` 替換 generic array，讓 Yosys
映射到 UP5K 的 single-port SPRAM primitive。

若換到 Xilinx/Intel FPGA，通常應寫 wrapper 讓 RAM inference 或 primitive 符合該器件；同時保持
介面時序為「送 address 後下一拍拿到 data」。

## 加入自己的 peripheral

最小 MMIO slave 寫法可參考 `icebreaker.v` 的 GPIO：

1. decode 一段不和現有元件重疊的 address。
2. 偵測 `iomem_valid && !iomem_ready`。
3. 下一拍把 `iomem_ready` 拉高一個 cycle。
4. read 設定 `iomem_rdata`；write 依 `iomem_wstrb` 更新 byte。
5. firmware 用 `volatile uint32_t *` 存取相同位址。

`volatile` 很重要，否則 compiler 可能移除或重排看似多餘的 I/O access。
