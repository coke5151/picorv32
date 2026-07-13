#ifdef ICEBREAKER
#  define MEM_TOTAL 0x20000 /* iCEBreaker SPRAM：128 KiB */
#elif HX8KDEMO
#  define MEM_TOTAL 0x200 /* HX8K 範例 scratchpad：512 bytes */
#else
#  error "Set -DICEBREAKER or -DHX8KDEMO when compiling firmware.c"
#endif

MEMORY
{
    /* CPU reset vector、firmware 燒錄 offset 與這個 ORIGIN 三者必須一致。 */
    FLASH (rx)      : ORIGIN = 0x00100000, LENGTH = 0x400000 /* firmware 可用範圍：4 MiB */
    RAM (xrw)       : ORIGIN = 0x00000000, LENGTH = MEM_TOTAL
}

SECTIONS {
    /* 可執行 code 與唯讀常數留在 Flash，CPU 透過 XIP 直接讀取。 */
    .text :
    {
        . = ALIGN(4);
        *(.text)           /* 程式碼 */
        *(.text*)
        *(.rodata)         /* 唯讀常數、字串等 */
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
        _etext = .;        /* Flash 中 code/rodata 的結尾 */
        _sidata = _etext;  /* .data 初始內容在 Flash 的起點，供 start.s 搬移 */
    } >FLASH


    /* 有初始值的可寫資料：執行位址在 RAM，但初始內容的 load address 在 Flash。
       start.s 開機時會把 _sidata 複製到 _sdata.._edata。 */
    .data : AT ( _sidata )
    {
        . = ALIGN(4);
        _sdata = .;        /* RAM 中 .data 起點 */
        _ram_start = .;    /* RAM 已使用區域起點，供簡易 allocator/回收程式參考 */
        . = ALIGN(4);
        *(.data)
        *(.data*)          /* .data* sections */
        *(.sdata)
        *(.sdata*)          /* .sdata* sections */
        . = ALIGN(4);
        _edata = .;        /* RAM 中 .data 結尾 */
    } >RAM

    /* 未初始化的全域/靜態資料不占 Flash 空間，由 start.s 清成 0。 */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* .bss 起點 */
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;         /* .bss 結尾 */
    } >RAM

    /* heap 從已配置資料之後開始；stack 則從 RAM 尾端往低位址成長。 */
    .heap :
    {
        . = ALIGN(4);
        _heap_start = .;    /* heap 起點 */
    } >RAM
}
