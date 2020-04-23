BaseOfBoot    equ    0x7C00
BaseOfLoader  equ    0x9000
BaseOfKernel  equ    0xB000

GDTEntry      equ    0xA000
GDTSize       equ    0xA000 + 4

;8259A Ports
MASTER_ICW1_PORT     equ  0x20
MASTER_ICW2_PORT     equ  0x21
MASTER_ICW3_PORT     equ  0x21
MASTER_ICW4_PORT     equ  0x21
MASTER_OCW1_PORT     equ  0x21
MASTER_OCW2_PORT     equ  0x20
MASTER_OCW3_PORT     equ  0x20

SLAVE_ICW1_PORT      equ  0xA0
SLAVE_ICW2_PORT      equ  0xA1
SLAVE_ICW3_PORT      equ  0xA1
SLAVE_ICW4_PORT      equ  0xA1
SLAVE_OCW1_PORT      equ  0xA1
SLAVE_OCW2_PORT      equ  0xA0
SLAVE_OCW3_PORT      equ  0xA0

MASTER_EIO_PORT      equ  0x20
MASTER_IMR_PORT      equ  0x21
MASTER_IRR_PORT      equ  0x20
MASTER_ISR_PORT      equ  0x20

SLAVE_EIO_PORT       equ  0xA0
SLAVE_IMR_PORT       equ  0xA1
SLAVE_IRR_PORT       equ  0xA0
SLAVE_ISR_PORT       equ  0xA0

; Segment Attribute
DA_32     equ    0X4000   ;32bits in protected mode
DA_DR     equ    0x90     ;只读
DA_DRW    equ    0x92     ;可读写
DA_DRWA   equ    0x93     ;已访问可读写
DA_C      equ    0x98     ;只执行
DA_CR     equ    0x9A     ;可执行可读
DA_CCO    equ    0x9C     ;只执行一致代码段
DA_CCOR   equ    0x9E     ;可执行可读一致代码段
DA_LIMIT_4K    equ       0x8000

;Special Attribute
DA_LDT       equ    0x82
;Gate Attr
DA_TaskGate  equ    0x85   ;任务门类型值
DA_386TSS    equ    0x89   ;可用 386 任务状态段类型值
DA_386CGate  equ    0x8C   ;386 调用门类型值
DA_386IGate  equ    0x8E   ;386 中断门类型值
DA_386TGate  equ    0x8F   ;386 陷阱门类型值

; Segment Privilege
DA_DPL0		equ	  0x00    ; DPL = 0
DA_DPL1		equ	  0x20    ; DPL = 1
DA_DPL2		equ	  0x40    ; DPL = 2
DA_DPL3		equ	  0x60    ; DPL = 3

; Selector Attribute
; RPL
SA_RPL0   equ    0
SA_RPL1   equ    1
SA_RPL2   equ    2
SA_RPL3   equ    3
;TI
SA_TIG    equ    0  ;GDT
SA_TIL    equ    4  ;LDT

PG_P    equ    1    ; 页存在属性位
PG_RWR  equ    0    ; R/W 属性位值, 读/执行
PG_RWW  equ    2    ; R/W 属性位值, 读/写/执行
PG_USS  equ    0    ; U/S 属性位值, 系统级
PG_USU  equ    4    ; U/S 属性位值, 用户级

; Segment Definition
; Usage : Descriptor   Base   Limit  Attr
%macro Descriptor 3
	dw    %2 & 0xFFFF                         ;段界限
	dw    %1 & 0xFFFF                         ;段基址
	db    (%1 >> 16) & 0xFF                   ;段基址1
	dw    ((%2 >> 8) & 0xF00) | (%3 & 0xF0FF) ;属性1 + 段界限 + 属性2
	db    (%1 >> 24) & 0xFF                   ;段基址3
%endmacro

; Gate Definition
; Usage : Selector offset count Attr
%macro Gate 4
	dw    %2 & 0xFFFF
	dw    %1
	dw    (%3 & 0x1F) | ((%4 << 8) & 0xFF00)
	dw    (%2 >> 16) & 0xFFFF
%endmacro

;%macro VideoPrint 2
;	mov ax, VideoSelector
;	mov gs, ax
;	
;	mov edi, (12 * 80 + %2)*2
;	mov ah, 0x8a                ;8位设置颜色 7:设置闪烁 4-6:设置背景色rgb 3:设置高亮 0-2前景色rgb
;	mov al, %1
;	mov [gs:edi], ax
;%endmacro