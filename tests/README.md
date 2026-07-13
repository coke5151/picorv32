# RISC-V 指令測試導覽

本目錄放的是從 `riscv-tests` 衍生的 RV32 指令級測試，每個 `.S` 通常集中驗證一種 instruction，
例如 `add.S`、`lw.S`、`jal.S`。它們會和 `firmware/` 一起連結，並不是各自可直接燒入 FPGA 的
完整程式。

## 檔案結構

- `riscv_test.h`：定義 test entry、pass/fail 和 PicoRV32 test environment。
- `test_macros.h`：產生常見算術、branch、load/store test pattern 的 macro。
- `simple.S`：最小測試範例。
- `mul*.S`、`div*.S`、`rem*.S`：RV32M extension；硬體要開啟對應乘除法。
- 其他 `.S`：RV32I base instruction 測試。

## 如何閱讀一個測試

先看檔尾如何回報 pass/fail，再回頭展開 `TEST_*` macro。macro 會準備 operand、執行待測 instruction，
並比較實際與預期值。測試中的 register number 和立即值常刻意涵蓋邊界條件，不是一般應用程式
的寫法。

這些測試適合驗證 CPU 修改沒有破壞 ISA；它們不能取代 SoC 的 UART、Flash、GPIO 與 timing 測試。
