# RTL 模組完整索引

本頁涵蓋 repository 內 41 個 Verilog 檔案、61 個 `module` 宣告。它的目的不是取代原始碼，而是先回答
三件事：這個 module 做什麼、能不能合成、應該從哪個介面開始讀。路徑是 module 身分的一部分；許多
測試檔都使用通用名稱 `testbench`、`top` 或 `system`，只應由各自的 Makefile／script 單獨編譯。

## 圖例與共同規則

| 類型 | 意義 |
| --- | --- |
| 可合成 | 可進入 synthesis；仍需依目標 FPGA/ASIC 檢查 primitive 與 timing |
| 包裝器 | 可合成，但主要工作是協定轉換、pin 或建置工具邊界 |
| 模擬 | 含 `initial`、`$readmemh`、時脈產生器或 behavioral model，不應放入硬體 |
| Formal | 使用 `assume`、`assert`、`restrict`、`$anyconst` 等形式驗證語意 |
| 綜合量測 | 可合成的刻意配置，只用來比較面積／速度，不是完整 SoC |

所有 PicoRV32 Native Memory transaction 都以 `mem_valid && mem_ready` 完成。`mem_wstrb == 0` 是讀取，
非零 bit 分別代表四個 byte lane。AXI、Wishbone wrapper 不負責 address decode；外部仍需接 memory 與
peripheral。

## CPU 與匯流排：`picorv32.v`

| Module | 類型 | 職責與閱讀重點 |
| --- | --- | --- |
| `picorv32` | 可合成 | RV32I/E 核心，可選 RVC、PCPI 乘除法、IRQ 與 trace。先讀 parameter、Native Memory／PCPI／IRQ port，再追 `cpu_state` 與 `mem_state`；它本身不含一般用途 RAM。 |
| `picorv32_regs` | 可合成 | 預設的外接 register-file 範例，透過 `PICORV32_REGS` 選用。位址以反相索引避開 x0；替換時要保持讀寫 latency 與 Q-register 配置。 |
| `picorv32_pcpi_mul` | 可合成 | 迭代式 RV32M 乘法器；`STEPS_AT_ONCE`／`CARRY_CHAIN` 在 cycle 數與組合路徑間取捨。完成時以 `pcpi_ready`、`pcpi_wr` 回寫。 |
| `picorv32_pcpi_fast_mul` | 可合成 | 直接 33×33 乘法、較容易推導 DSP 的快速版本；資源較大，和 `ENABLE_MUL` 擇一使用。 |
| `picorv32_pcpi_div` | 可合成 | 逐 bit restoring divider，處理 DIV/DIVU/REM/REMU、符號修正、除零與 overflow 的 ISA 結果。 |
| `picorv32_axi` | 包裝器 | `picorv32` 加 `picorv32_axi_adapter` 的 AXI4-Lite master 外殼；CPU 功能 parameter 會向內傳遞。 |
| `picorv32_axi_adapter` | 可合成 | 把單一 Native transaction 拆成 AXI AW/W/B 或 AR/R channel。各 channel 可獨立 back-pressure，只有 response handshake 後才回 `mem_ready`。 |
| `picorv32_wb` | 包裝器 | PicoRV32 Wishbone master 版本；以 `cyc/stb` 發起、`ack` 結束，`sel` 對應 `mem_wstrb`。 |

## 根目錄回歸測試

| 路徑／Module | 類型 | 職責與閱讀重點 |
| --- | --- | --- |
| `testbench_ez.v` / `testbench` | 模擬 | 不需 RISC-V toolchain 的最小範例；內嵌幾條 instruction，最適合第一次看 valid/ready。 |
| `testbench.v` / `testbench` | 模擬 | 產生 clock/reset、VCD/trace、timeout，實例化下方 wrapper；不是待合成 top。 |
| `testbench.v` / `picorv32_wrapper` | 模擬 | 依 `AXI_TEST` 選 Native 或 AXI CPU，加入 IRQ stimulus、firmware memory 與測試結果 MMIO。 |
| `testbench.v` / `axi4_memory` | 模擬 | 可獨立延遲五個 AXI channel 的 memory/MMIO model，用來驗證 adapter 面對 back-pressure 的行為。 |
| `testbench_wb.v` / `testbench` | 模擬 | Wishbone 回歸入口，負責 reset、VCD、trace 與 timeout。 |
| `testbench_wb.v` / `picorv32_wrapper` | 模擬 | 將 `picorv32_wb`、IRQ stimulus 與 `wb_ram` 接在一起。 |
| `testbench_wb.v` / `wb_ram` | 模擬 | Wishbone RAM 與測試 MMIO model；在 `cyc && stb` 後產生 `ack`，並依 `sel` 寫 byte lane。 |

## PicoSoC 與板級模組

| 路徑／Module | 類型 | 職責與閱讀重點 |
| --- | --- | --- |
| `picosoc/picosoc.v` / `picosoc` | 可合成 | SoC interconnect：整合 CPU、scratchpad、SPI Flash XIP、UART，並把 `0x03xx_xxxx` 以上轉給板級 MMIO。 |
| `picosoc/picosoc.v` / `picosoc_regs` | 可合成 | 配合 PicoSoC 的同步雙讀 register file；`PICORV32_REGS` macro 讓 core 使用此實作。 |
| `picosoc/picosoc.v` / `picosoc_mem` | 可合成 | 通用 32-bit scratchpad，支援 byte write；送出 request 後下一拍 `ready`，可被板級 RAM module 取代。 |
| `picosoc/spimemio.v` / `spimemio` | 可合成 | Memory-mapped SPI Flash controller；管理 XIP cache line、config register、CRM/QSPI/DDR 模式及 manual I/O。 |
| `picosoc/spimemio.v` / `spimemio_xfer` | 可合成 | 實際 bit/edge 傳輸狀態機；把 command/address/dummy/data phase 轉成 SPI IO、OE、clock 與 chip-select。 |
| `picosoc/simpleuart.v` / `simpleuart` | 可合成 | 最小 8N1 UART TX/RX。MMIO write 在整個 transmit 期間 back-pressure；RX 只保留一個尚未讀取的 byte。 |
| `picosoc/ice40up5k_spram.v` / `ice40up5k_spram` | 可合成、器件限定 | 以四個 `SB_SPRAM256KA` 組成 32-bit、byte-write scratchpad；只適用有該 primitive 的 iCE40-UP5K。 |
| `picosoc/icebreaker.v` / `icebreaker` | 板級包裝器 | iCEBreaker top：reset counter、SPRAM、SPI/UART pin、LED MMIO 與 PicoSoC；port 必須和 PCF 一致。 |
| `picosoc/hx8kdemo.v` / `hx8kdemo` | 板級包裝器 | iCE40-HX8K demo board top：block-RAM PicoSoC、UART、SPI、LED/debug pin 與 reset。 |
| `picosoc/spiflash.v` / `spiflash` | 模擬 | Behavioral SPI Flash model，解析 serial/dual/quad/DDR read command；不是可燒入 FPGA 的 controller。 |
| `picosoc/spiflash_tb.v` / `testbench` | 模擬 | 單獨驅動 `spimemio` 與 Flash model，比較不同 mode 的讀取資料與效能。 |
| `picosoc/icebreaker_tb.v` / `testbench` | 模擬 | iCEBreaker 板級模擬，接 behavioral Flash、UART stimulus 與 timeout。 |
| `picosoc/hx8kdemo_tb.v` / `testbench` | 模擬 | HX8K 板級模擬，驗證開機、Flash XIP、UART／LED 外部行為。 |

## Benchmark 與語言壓力測試

| 路徑／Module | 類型 | 職責與閱讀重點 |
| --- | --- | --- |
| `dhrystone/testbench.v` / `testbench` | 模擬 | Dhrystone memory model，使用 look-ahead interface 做零等待存取，並可輸出 instruction trace/timing。 |
| `dhrystone/testbench_nola.v` / `testbench` | 模擬 | 相同 benchmark 的 Native valid/ready 版本，用來比較不用 look-ahead 時的週期。 |
| `scripts/cxxdemo/testbench.v` / `testbench` | 模擬 | 載入 bare-metal C++ firmware，驗證 startup、constructor 與簡易輸出 MMIO。 |
| `scripts/csmith/testbench.v` / `testbench` | 模擬 | 執行 Csmith 產生的隨機 C 程式；memory-mapped 結果碼用來判定 pass/fail。 |
| `scripts/torture/testbench.v` / `testbench` | 模擬 | 執行 riscv-torture 隨機 ISA workload，提供大 memory、console 與錯誤交易檢查。 |
| `scripts/tomthumbtg/testbench.v` / `testbench` | 模擬 | 載入第三方 random instruction generator 輸出，回報錯誤 test case 或成功結束碼。 |
| `scripts/romload/testbench.v` / `testbench` | 模擬 | 測試 ROM boot loader 載入 RAM 後執行 firmware 的流程，並提供 console MMIO。 |

## FPGA／綜合工具範例

| 路徑／Module | 類型 | 職責與閱讀重點 |
| --- | --- | --- |
| `scripts/icestorm/example.v` / `top` | 可合成範例 | 最小 iCE40 CPU+RAM+LED 系統；示範 reset、Native memory 與 MMIO，不含 PicoSoC 的 SPI/UART。 |
| `scripts/icestorm/example_tb.v` / `testbench` | 模擬 | 上述最小 iCE40 系統的 LED/VCD 測試。 |
| `scripts/presyn/testbench.v` / `testbench` | 模擬 | 對預先綜合的 core netlist 做 memory handshake 與 VCD 驗證。 |
| `scripts/presyn/testbench.v` / `picorv32_regs` | 模擬／技術映射 | 配合 presynthesis 流程的同步 register-file model；port 命名是該流程的 netlist boundary。 |
| `scripts/yosys/synth_gates.v` / `top` | 綜合量測 | 極小 core configuration 的 Yosys gate-synthesis top，直接暴露 Native interface。 |
| `scripts/quartus/synth_area_top.v` / `top_small` | 綜合量測 | 移除 counters、misalign／illegal trap 等功能，量測最小面積。 |
| 同檔 / `top_regular` | 綜合量測 | 預設功能與 look-ahead interface 的基準配置。 |
| 同檔 / `top_large` | 綜合量測 | 啟用 RVC、barrel shifter、PCPI、mul、IRQ 的大型配置。 |
| `scripts/vivado/synth_area_top.v` / `top_small` | 綜合量測 | Vivado 版最小面積 top；功能組合和 Quartus 版對齊。 |
| 同檔 / `top_regular` | 綜合量測 | Vivado 版預設面積基準。 |
| 同檔 / `top_large` | 綜合量測 | Vivado 版大型功能基準。 |
| `scripts/quartus/system.v` / `system` | 可合成範例 | CPU、16 KiB memory、字元輸出 MMIO；`FAST_MEMORY` 選 look-ahead 或保守 valid/ready 實作。 |
| `scripts/vivado/system.v` / `system` | 可合成範例 | 與 Quartus system 同角色，預設 memory timing 選項因工具實驗設定而異。 |
| `scripts/quartus/system_tb.v` / `system_tb` | 模擬 | Quartus system 的 clock/reset、console、timeout 測試平台。 |
| `scripts/vivado/system_tb.v` / `system_tb` | 模擬 | Vivado system 的對應測試平台。 |
| `scripts/quartus/tabtest.v` / `top` | 綜合量測 | 在所有 AXI／IRQ I/O 前後插四級 register，隔離 I/O timing 以量測 core。 |
| 同檔 / `delay4` | 可合成 | 可參數化寬度的四級 pipeline delay；無 reset，前四拍輸出未定。 |
| `scripts/vivado/tabtest.v` / `top` | 綜合量測 | Vivado 對應的 AXI I/O pipeline 測試 top。 |
| 同檔 / `delay4` | 可合成 | 與 Quartus 版相同的四級 pipeline delay。 |

## Formal verification：`scripts/smtbmc/`

這些 module 是驗證 harness，不是一般 RTL testbench。輸入可由 solver 任意選擇；`assume`／`restrict`
限定合法環境，`assert` 才是要證明的性質。若刪掉環境限制，常會得到 AXI slave 永不回覆之類無意義
counterexample。

| 路徑／Module | 類型 | 證明目標 |
| --- | --- | --- |
| `scripts/smtbmc/axicheck.v` / `testbench` | Formal | AXI master 在 back-pressure 下維持 valid、address、data 穩定；限制 response ordering、單筆 outstanding 與 bounded response。 |
| `scripts/smtbmc/axicheck2.v` / `testbench` | Formal | 兩個相同 AXI core 在等價 handshake／response 環境下產生相同 observable bus 行為。 |
| `scripts/smtbmc/mulcmp.v` / `testbench` | Formal | 對任意 RV32M instruction 與 operands，迭代式和快速 PCPI multiplier 完成後結果一致。 |
| `scripts/smtbmc/notrap_validop.v` / `testbench` | Formal | 在只取合法、非 branch/load/store instruction 且 memory bounded-stall 的假設下，core 不進 trap。 |
| `scripts/smtbmc/tracecmp.v` / `testbench` | Formal | 兩個可採不同 microarchitecture parameter 的 core，雖完成時間不同，退休 trace 序列仍等價。 |
| `scripts/smtbmc/tracecmp2.v` / `testbench` | Formal | 用共享任意 read data 與交易配對狀態，比較兩個 core 的 memory side effects 與 trace。 |
| `scripts/smtbmc/tracecmp3.v` / `testbench` | Formal | 比較內建與外接 PCPI 路徑的 observable execution，並把外部 PCPI response 納入 solver 環境。 |
| `scripts/smtbmc/opcode.v` / helper functions | Formal 輔助 | 集中判斷 opcode 是否有效、是否屬於 branch/load/store；由 `notrap_validop.v` include，本身沒有 `module`。 |

## 修改時的邊界檢查

1. 改 `picorv32` port 或 parameter 時，同步檢查 AXI/Wishbone wrapper、三個根目錄 testbench 及面積 top。
2. 改 Native handshake 時，同步檢查 `picosoc_mem`、`spimemio`、`simpleuart` 與所有 memory model。
3. 改 CPU ISA 功能時，同步對齊 compiler `-march`、PCPI 單元與 `tests/`。
4. 改 PicoSoC address map 時，同步修改 RTL decode、firmware MMIO、linker script、板級 top 與文件。
5. 只編譯當前流程列出的 source；不要把 repository 內所有同名 `testbench` 一次交給 simulator。
