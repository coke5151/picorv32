# Firmware 從編譯到執行

## 檔案如何串起來

```text
start.s + firmware.c
        │ assembler / compiler
        ▼
      .o files + sections.lds
        │ linker
        ▼
 firmware.elf ── objcopy ──► firmware.bin（燒進 Flash）
        └────── 轉換 ──────► firmware.hex（testbench 載入）
```

ELF 包含 section、symbol 和 debug 資訊，適合反組譯與除錯；BIN 只有連續 raw bytes；HEX 是文字
格式，常用 `$readmemh` 初始化模擬 memory。三者不是交換副檔名就能互換。

## `start.s` 做的事

C 的 `main()` 不能在 reset 後立刻安全執行。startup code 依序：

1. 清除一般用途 register；x2 (`sp`) 已由 PicoRV32 的 `STACKADDR` 初始化。
2. 清除 scratchpad RAM。
3. 從 Flash 的 load address 複製 `.data` 初值到 RAM。
4. 清除 `.bss`。
5. 呼叫 `main()`；若 `main` return，就停在無限迴圈。

範例在各階段寫不同 LED bit pattern，硬體沒 UART 時也能看出卡在哪一步。

## Linker script

`picosoc/sections.lds` 定義兩個 memory region：

- `FLASH (rx)`：程式碼、唯讀資料，以及 `.data` 的初始內容。
- `RAM (xrw)`：��行期間的 `.data`、`.bss`、heap、stack。

`.data : AT(_sidata)` 表示執行位址（VMA）在 RAM，但載入位址（LMA）在 Flash。startup 使用
`_sidata`、`_sdata`、`_edata` 把內容搬到正確位置。未初始化的 `.bss` 不必占 Flash 空間。

## Compiler 設定必須符合硬體

重點選項通常包括：

- `-march=rv32imc`：允許 I、M、C；硬體也要開 M/C。
- `-mabi=ilp32`：32-bit int、long、pointer ABI。
- `-ffreestanding` / `-nostdlib`：沒有作業系統與一般 C runtime。
- `-T sections.lds`：使用專案 linker script。

若看到 illegal instruction，先用 `riscv*-objdump -d firmware.elf` 檢查是否產生硬體沒開的 M、C、
atomic 或 floating-point instruction。

## MMIO 程式寫法

```c
#define reg_uart_data (*(volatile uint32_t *)0x02000008)
#define reg_leds      (*(volatile uint32_t *)0x03000000)

reg_leds = 1;
reg_uart_data = 'A';
```

這不是在存取一般 RAM。address decoder 會把 store 導到 UART/GPIO。UART transmit 忙碌時，
`simpleuart` 讓 `mem_ready` 保持低，CPU 的 store 會自然停住，不需要 firmware 另外輪詢 busy bit。

## Stack、heap 與容量

stack 從 RAM 尾端往低位址成長，`.data`/`.bss`/heap 從低位址往高位址使用。此範例沒有完整 allocator
和 stack overflow protection；加入大型 array、遞迴或 `malloc` 前，要從 ELF map/size 檢查兩邊
是否相撞。

## 建議的第一支程式

先只保留 UART 初始化、印固定字串、LED counter。確認 bitstream、clock、reset、Flash offset、UART
baud 都正確後，再加入 interrupt、SPI write 或大型 C library，除錯範圍會小很多。
