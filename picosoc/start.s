.section .text

start:

# 清除 register file。x0 固定為 0；x2 (sp) 已由 CPU reset logic 設成 STACKADDR。
addi x1, zero, 0
# x2 (sp) 不可在這裡清成 0
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0
addi x16, zero, 0
addi x17, zero, 0
addi x18, zero, 0
addi x19, zero, 0
addi x20, zero, 0
addi x21, zero, 0
addi x22, zero, 0
addi x23, zero, 0
addi x24, zero, 0
addi x25, zero, 0
addi x26, zero, 0
addi x27, zero, 0
addi x28, zero, 0
addi x29, zero, 0
addi x30, zero, 0
addi x31, zero, 0

# LED=1：已完成 register 初始化，可用 LED pattern 判斷開機卡在哪個階段。
li a0, 0x03000000
li a1, 1
sw a1, 0(a0)

# 清除整個 scratchpad RAM，從位址 0 一直寫到 sp（RAM 尾端）。
li a0, 0x00000000
setmemloop:
sw a0, 0(a0)
addi a0, a0, 4
blt a0, sp, setmemloop

# LED=3：RAM 清除完成
li a0, 0x03000000
li a1, 3
sw a1, 0(a0)

# 把有初始值的 .data 從 Flash load address (_sidata) 搬到 RAM (_sdata.._edata)。
la a0, _sidata
la a1, _sdata
la a2, _edata
bge a1, a2, end_init_data
loop_init_data:
lw a3, 0(a0)
sw a3, 0(a1)
addi a0, a0, 4
addi a1, a1, 4
blt a1, a2, loop_init_data
end_init_data:

# LED=7：.data 搬移完成
li a0, 0x03000000
li a1, 7
sw a1, 0(a0)

# 清除未初始化的全域/靜態變數區 .bss。
la a0, _sbss
la a1, _ebss
bge a0, a1, end_init_bss
loop_init_bss:
sw zero, 0(a0)
addi a0, a0, 4
blt a0, a1, loop_init_bss
end_init_bss:

# LED=15：C runtime 準備完成
li a0, 0x03000000
li a1, 15
sw a1, 0(a0)

# 進入 C main；如果 main return，就留在下面的無限迴圈，避免跑進未知內容。
call main
loop:
j loop

.global flashio_worker_begin
.global flashio_worker_end

.balign 4

flashio_worker_begin:
# 這段函式執行時會先被 C code 複製到 RAM，因為切換 Flash 到 manual mode 後不能同時從 Flash 取指。
# a0：資料 buffer；a1：byte 數；a2：可選 WREN command（0 表示不用）

# SPI controller config register 位址
li   t0, 0x02000000

# CS 維持 high，IO0 設為 output
li   t1, 0x120
sh   t1, 0(t0)

# 開啟 manual SPI control；接下來每次 register write 直接驅動 pin
sb   zero, 3(t0)

# 如果 a2 非零，先送出 write-enable command
beqz a2, flashio_worker_L1
li   t5, 8
andi t2, a2, 0xff
flashio_worker_L4:
srli t4, t2, 7
sb   t4, 0(t0)
ori  t4, t4, 0x10
sb   t4, 0(t0)
slli t2, t2, 1
andi t2, t2, 0xff
addi t5, t5, -1
bnez t5, flashio_worker_L4
sb   t1, 0(t0)

# 逐 byte、逐 bit 進行 full-duplex SPI transfer
flashio_worker_L1:
beqz a1, flashio_worker_L3
li   t5, 8
lbu  t2, 0(a0)
flashio_worker_L2:
srli t4, t2, 7
sb   t4, 0(t0)
ori  t4, t4, 0x10
sb   t4, 0(t0)
lbu  t4, 0(t0)
andi t4, t4, 2
srli t4, t4, 1
slli t2, t2, 1
or   t2, t2, t4
andi t2, t2, 0xff
addi t5, t5, -1
bnez t5, flashio_worker_L2
sb   t2, 0(a0)
addi a0, a0, 1
addi a1, a1, -1
j    flashio_worker_L1
flashio_worker_L3:

# 回到 memory-mapped XIP mode，return 後 CPU 才能繼續從 Flash 取指
li   t1, 0x80
sb   t1, 3(t0)

ret

.balign 4
flashio_worker_end:
