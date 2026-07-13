# Dhrystone Benchmark 導覽

Dhrystone 是老牌的整數 workload benchmark，這裡用它量測 PicoRV32 執行一般 C code 的速度。它不
測 floating point、memory bandwidth 或真實應用效能，因此分數只適合在相同 compiler flags、
clock 與 CPU 設定下比較。

## 重要檔案

- `dhry_1.c`、`dhry_2.c`、`dhry.h`：benchmark 主體。
- `start.S`、`sections.lds`：bare-metal startup 和 memory layout。
- `stdlib.c`、`syscalls.c`：無作業系統環境需要的最小函式。
- `testbench.v`：正常 benchmark 模擬平台。
- `testbench_nola.v`：不同 memory look-ahead 設定的測試平台。
- `Makefile`：編譯 firmware、執行模擬並產生結果。

## 看結果前先記錄

至少記下 core parameter、clock frequency、compiler 版本、optimization level、`-march/-mabi` 與
memory wait state。只比較 DMIPS/MHz 仍可能受到 compiler 與 memory model 影響。

`README` 是上游英文操作說明；本檔提供用途和閱讀重點。
