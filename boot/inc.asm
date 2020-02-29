
; Segment Attribute
DA_32     equ    0X4000
DA_DR     equ    0x90
DA_DRW    equ    0x92
DA_DRWA   equ    0x93
DA_C      equ    0x98
DA_CR     equ    0x9A
DA_CCO    equ    0x9C
DA_CCOR   equ    0x9E

; Selector Attribute
; RPL
SA_RPL0   equ    0
SA_RPL1   equ    1
SA_RPL2   equ    2
SA_RPL3   equ    3
;TI
SA_TIG    equ    0  ;GDT
SA_TIL    equ    4  ;LDT

; Segment Definition
; Usage : Descriptor   Base   Limit  Attr
%macro Descriptor 3
	dw    %2 & 0xFFFF                         ;段界限
	dw    %1 & 0xFFFF                         ;段基址
	db    (%1 >> 16) & 0xFF                   ;段基址1
	dw    ((%2 >> 8) & 0xF00) | (%3 & 0xF0FF) ;属性1 + 段界限 + 属性2
	db    (%1 >> 24) & 0xFF                   ;段基址3
%endmacro

%macro VideoPrint 2
	mov ax, VideoSelector
	mov gs, ax
	
	mov edi, (12 * 80 + %2)*2
	mov ah, 0x8a                ;8位设置颜色 7:设置闪烁 4-6:设置背景色rgb 3:设置高亮 0-2前景色rgb
	mov al, %1
	mov [gs:edi], ax
%endmacro