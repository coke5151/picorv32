# 軟體與工具鏈索引

本頁補足 RTL 之外的專案模組。PicoRV32 repository 同時包含可重用 CPU、兩套 firmware、ISA 測試、
benchmark、FPGA tool flow 與 formal harness；它們不是一個巨大的單一 build。開始前先選「要驗證 CPU、
跑 PicoSoC、還是量測某個 EDA tool」，再使用該目錄的 Makefile。

## 根目錄：CPU 回歸入口

| 檔案 | 角色 | 產物／注意事項 |
| --- | --- | --- |
| `Makefile` | 根目錄 orchestrator | 編譯 test firmware、Native/AXI/Wishbone 模擬、Verilator、Yosys formal/synthesis；`download-tools` 會做大型外部安裝，不是一般測試必要步驟。 |
| `picorv32.core` | FuseSoC manifest | 宣告 RTL source、target 與 parameter；用 FuseSoC 時才讀取。 |
| `testbench.cc` | Verilator harness | 驅動 clock/reset、VCD 與退出條件；對應 top 是 `picorv32_wrapper`。 |
| `showtrace.py` | trace decoder | 將 36-bit PicoRV32 trace 轉成較可讀的 PC／memory event；輸入來自 `+trace`。 |
| `shell.nix` | Nix 開發環境 | 提供可重現工具集合；不參與 RTL 功能。 |

## `firmware/`：根目錄自我測試程式

| 檔案／群組 | 角色 |
| --- | --- |
| `start.S` | reset/IRQ entry、register 與 RAM 初始化，呼叫 C 測試與 `tests/*.S`。 |
| `sections.lds` | testbench memory 的 section、stack 與 symbol 配置。 |
| `firmware.h` | console／test MMIO、函式與 custom instruction 共用宣告。 |
| `custom_ops.S` | `getq`、`setq`、`retirq`、`maskirq`、`waitirq`、`timer` 的 assembly wrapper。 |
| `irq.c` | IRQ mask、timer、queued register 與 fault recovery 測試。 |
| `hello.c`、`sieve.c`、`multest.c` | 一般 C、memory、乘法功能測試。 |
| `print.c`、`stats.c` | 最小輸出函式與 cycle/instruction counter 報告。 |
| `makehex.py` | raw binary 轉 `$readmemh` 使用的 word-oriented HEX；第二個參數限制輸出大小。 |
| `riscv.ld`、`riscv.ld.orig` | 歷史／參考 linker script；根目錄主要 build 使用 `sections.lds`。 |

## `tests/`：ISA 單元測試

| 檔案／群組 | 角色 |
| --- | --- |
| `riscv_test.h` | PicoRV32 test environment、entry、pass/fail 回報。 |
| `test_macros.h` | 算術、branch、load/store 等重複 test pattern。 |
| `simple.S` | 最小 standalone pattern，適合先理解 harness。 |
| `add.S`～`xori.S` | RV32I 指令各自的邊界案例；由根目錄 Makefile 全部連進同一 firmware。 |
| `mul*.S`、`div*.S`、`rem*.S` | RV32M 測試；硬體與 toolchain 必須啟用 M extension。 |

這些 `.S` 檔不是 40 多個獨立開機映像。Makefile 以 `TEST_FUNC_NAME` 等 macro 為每個檔案產生函式，
再由 `firmware/start.S` 依序呼叫。

## `picosoc/`：可上板的完整範例

| 檔案／群組 | 角色 |
| --- | --- |
| `Makefile` | 產生 firmware、iCE40 bitstream、simulation 與 programming command；`iceb*`／`hx8k*` target 對應不同板。 |
| `start.s` | 從 Flash 執行的 startup；初始化 register/RAM、搬 `.data`、清 `.bss`、呼叫 `main`。 |
| `sections.lds` | `FLASH=0x0010_0000`、RAM section、載入位址與 stack/heap symbol。 |
| `firmware.c` | UART menu、SPI mode/效能測試、LED 與 Flash 操作示範。 |
| `*.pcf` | Lattice pin constraint；只能用在對應 board/revision。 |
| `*.core` | FuseSoC 對 PicoSoC、board、Flash model 的 source/target 描述。 |
| `performance.py` | 將實測資料轉成 `performance.png`；不參與硬體 build。 |

改開機位址時，`PROGADDR_RESET`、`sections.lds` 的 Flash origin 與 programmer offset 必須一起修改。

## `dhrystone/`：效能 benchmark

`dhry_1.c`、`dhry_2.c` 與 `dhry.h` 是 benchmark 主體；`start.S`、`sections.lds`、`syscalls.c`、
`stdlib.c` 提供 bare-metal runtime。`dhry_1_orig.c` 保留較接近原版的參考，不是預設 build 主體。
`testbench.v` 與 `testbench_nola.v` 分別量測 look-ahead 與 Native memory 路徑，不能直接把結果當成
不同 FPGA memory latency 下的通用 CoreMark/Dhrystone 效能。

## `scripts/`：依目的選擇的獨立流程

| 目錄 | 入口與資料流 | 外部依賴／風險 |
| --- | --- | --- |
| `icestorm/` | `firmware.*` → HEX → `example.v` → iCE40 bitstream／simulation | Yosys、nextpnr/ArachnePNR、IceStorm；pin 需配板。 |
| `vivado/` | area/speed/system TCL target，使用 `synth_area_top.v`、`system.v` | Xilinx Vivado；XDC 與 part 是範例設定。 |
| `quartus/` | area/speed/system QSF/TCL target | Intel Quartus；QSF/SDC 與 device 是範例。 |
| `yosys/` | `.ys` 讀入 core、設定 top、opt/techmap、輸出 gate netlist | `synth_gates.lib` 是實驗 library，不代表實際製程。 |
| `presyn/` | 先用 Yosys 產生 netlist，再以 `testbench.v` 跑 firmware | 注意自訂 register-file boundary 與 `picorv32_regs.txt`。 |
| `romload/` | boot ROM + RAM loader firmware／testbench | `map2debug.py`、`hex8tohex32.py` 是格式轉換工具。 |
| `cxxdemo/` | C++ firmware + startup/syscalls + Verilog testbench | freestanding C++，需確認 constructor、linker 與 ABI。 |
| `csmith/` | 產生隨機 C，編譯給 PicoRV32，和 reference/Spike 結果比較 | 可長時間執行；需 Csmith、RISC-V toolchain/Spike。 |
| `torture/` | riscv-torture generator → assembly → DUT/reference 比較 | 含外部專案 patch；版本差異會影響結果。 |
| `tomthumbtg/` | 第三方 generator 產生 test case，再由 testbench 回報 | `run.sh` 管理外部工具與多輪測試。 |
| `smtbmc/` | shell script 建 SMT model，formal harness 提供 assume/assert | 需要 Yosys-SMTBMC 與 solver；先理解環境假設。 |
| `yosys-cmp/` | 以 Yosys、Vivado、Synplify、LSE 比較 FPGA synthesis | 結果依版本、constraint、device，不能跨設定直接比較。 |

## 產物不要當原始碼提交

常見衍生檔包括 `.o`、`.elf`、`.bin`、`.hex`、`.map`、`.vvp`、`.vcd`、trace、solver model、
synthesis log/netlist、place-and-route database 與 bitstream。除非文件或回歸基準刻意追蹤它們，否則應
由 Makefile 重建。執行 `clean` 前仍要確認所在目錄，因為每個子流程有自己的產物清單。

## 建議的變更驗證矩陣

| 變更範圍 | 最小驗證 | 再加一道高信心驗證 |
| --- | --- | --- |
| 文件／註解 | 搜尋 module 索引、檢查 Markdown link、Verilog parse | `make test_ez` 確認未意外改 RTL token |
| CPU datapath/decode | `make test_ez` + ISA firmware regression | AXI/Wishbone、Verilator、formal trace compare |
| AXI/Wishbone adapter | 對應 bus testbench | `scripts/smtbmc/axicheck*.sh` |
| PCPI 乘除法 | RV32M tests | `mulcmp.sh` 與 random workload |
| PicoSoC address/MMIO | board testbench | 真板 UART/LED/Flash XIP smoke test |
| Startup/linker | 反組譯、section/map 檢查 | simulation 從 reset 跑到 `main`／成功碼 |
