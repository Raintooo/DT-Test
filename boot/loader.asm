%include "inc.asm"

org 0x9000

jmp ENTRY_SEGMENT

[section .gdt]
; GDT Definition
;                            段基址       段界限            段属性
GDT_ENTRY    :    Descriptor  0,           0,               0
CODE32_DES   :    Descriptor  0,         Code32SegLen-1,    DA_C + DA_32
VIDEO_DES    :    Descriptor  0xB8000,   0x7FFFF,           DA_DRWA + DA_32  
DATA32_DESC  :    Descriptor  0,         DataLength-1,      DA_DR + DA_32
STACK32_DESC :    Descriptor  0,         TopOfStack32Init,  DA_DRW + DA_32
CODE16_DESC  :    Descriptor  0,         0xFFFF,  DA_C
UPDATE_DESC  :    Descriptor  0,         0xFFFF,            DA_DRW
TASK_A_DESC  :    Descriptor  0,         TaskLdtLen - 1,    DA_LDT 

GdtLen  equ  $ - GDT_ENTRY
GdtPtr:
	dw GdtLen - 1		;GDT界限
	dd 0				;GDT基地址 16位代码段中计算

;as pointer point to every descriptor's base address	
Code32Selector    equ  (0x0001 << 3) + SA_TIG + SA_RPL0
VideoSelector     equ  (0x0002 << 3) + SA_TIG + SA_RPL0
DataSelector      equ  (0x0003 << 3) + SA_TIG + SA_RPL0
Stack32Selector   equ  (0x0004 << 3) + SA_TIG + SA_RPL0
Code16Selector    equ  (0x0005 << 3) + SA_TIG + SA_RPL0
UpdateSelector    equ  (0x0006 << 3) + SA_TIG + SA_RPL0
TaskALdtSelector  equ  (0x0007 << 3) + SA_TIG + SA_RPL0
;end [section .gdt]

[section .dat]
[bits 32]
DATA32_SEGMENT:
	DTOS            db  "DTOS!", 0
	DTOS_OFFSET     equ DTOS - $$
	HELLO_WORLD     db  "Hello World!", 0
	HELLO_OFFSET    equ HELLO_WORLD - $$
	BACK_TO_REAL    db  "Weclome back ", 0
	
DataLength  equ $ - DATA32_SEGMENT

TopOfStackInit  equ  0x7c00

[section .s16]
[bits 16]
ENTRY_SEGMENT:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, TopOfStackInit
	
	mov [BACK_TO_REAL_MODE + 3], cs
	
	; initialize GDT for 32 bits code segment 初始化 CODE32_DES 描述符中基地址值
	mov esi, CODE32_SEGMENT
	mov edi, CODE32_DES
	call InitDescItem
	
	mov esi, DATA32_SEGMENT
	mov edi, DATA32_DESC
	call InitDescItem
	
	mov esi, STACK32_SEGMENT
	mov edi, STACK32_DESC
	call InitDescItem
	
	mov esi, CODE16_SEGMENT
	mov edi, CODE16_DESC
	call InitDescItem
	
	;Init ldt
	mov esi, TASK_A_LDT_ENTRY
	mov edi, TASK_A_DESC
	call InitDescItem
	
	mov esi, TASK_A_STACK_SEGMENT
	mov edi, TASKA_STACK32_DESC
	call InitDescItem
	
	mov esi, TASK_A_CODE_SEGMENT
	mov edi, TASKA_CODE32_DESC
	call InitDescItem
	
	mov esi, TASK_A_DATA_SEGMENT
	mov edi, TASKA_DATA32_DESC
	call InitDescItem
	
	; initialize GDT pointer struct 初始化 GDT基地址
	mov eax, 0
	mov ax, cs
	shl eax, 4
	add eax, GDT_ENTRY
	mov dword [GdtPtr + 2], eax
	
	; 1. load GDT
	lgdt [GdtPtr]
	
	; 2. close interrupt
	cli
	
	; 3. open A20 : 将0x92端口 第3位置1 
	in al, 0x92
	or al, 00000010b
	out 0x92, al
	
	; 4. enter protect mode 
	;CRx寄存器控制CPU运行机制，CR0寄存器第0位即PE位(Protectioin Enable)，用于启用保护模式。
	mov eax, cr0		;set PE(first bit) as 1 
	or eax, 0x01
	mov cr0, eax
	
	; 5. jump to 32 bits code
	jmp dword Code32Selector : 0    ;通过选择子 获取对应段基址 再偏移0位
	
BACK_TO_ENTRY:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, TopOfStackInit

	in al, 0x92
	and al, 11111101b
	out 0x92, al
	
	sti
	
	mov bp, BACK_TO_REAL
	mov cx, 12
	mov dx, 0
	mov ax, 0x1301
	mov bx, 0x0007
	int 0x10
	
	jmp $

; esi --> code segment label
; edi --> descriptor label
InitDescItem:
	push eax

	mov eax, 0
	mov ax, cs
	shl eax, 4
	add eax, esi
	mov word [edi + 2], ax
	shr eax, 16
	mov byte [edi + 4], al
	mov byte [edi + 7], ah

	pop eax
	ret
	
[section .s16]
[bits 16]
CODE16_SEGMENT:
	mov ax, UpdateSelector
	mov gs, ax
	mov ds, ax
	mov fs, ax
	mov es, ax
	mov ss, ax
	
	; exit proctect mode
	mov eax, cr0
	and eax, 0x11111110
	mov cr0, eax
	
BACK_TO_REAL_MODE:
	jmp 0 : BACK_TO_ENTRY

Code16SegLen  equ $ - CODE16_SEGMENT

	
[section .s32]
[bits 32]
CODE32_SEGMENT:

	mov ax, VideoSelector
	mov gs, ax
	
	mov ax, DataSelector
	mov ds, ax
	
	mov ax, Stack32Selector
	mov ss, ax
	mov eax, TopOfStack32Init
	mov esp, eax
	
	mov ebp, DTOS_OFFSET
	mov dh, 1
	mov dl, 35
	mov bx, 0x0c
	call PrintString

	mov ebp, HELLO_OFFSET
	mov dh, 13
	mov dl, 35
	mov bx, 0x0c
	call PrintString
	
	mov ax, TaskALdtSelector
	lldt ax
	jmp TaskACode32Selector : 0 
	
	;jmp Code16Selector : 0


; print string by Graphics
; ds:ebp --> string address
; dx     --> dh: row  dl: col
; bx     --> attribute   ;8位设置颜色 7:设置闪烁 4-6:设置背景色rgb 3:设置高亮 0-2前景色rgb
PrintString:
	push cx
	push eax
	push ebp
	push edi
print:
	mov cl, [ds:ebp]
	cmp cl, 0
	je end
	
	mov eax, 80
	mul dh
	add al, dl
	shl eax, 1
	mov edi, eax
	mov ah, bl
	mov al, cl
	mov [gs:edi], ax
	
	inc ebp
	inc dl
	jmp print
end:
	pop edi
	pop ebp
	pop eax
	pop cx
	ret
	
Code32SegLen  equ  $ - CODE32_SEGMENT

[section .gs]
[bits 32]
STACK32_SEGMENT:
	times 1024*4 db 0

Stack32SegLen equ  $ - STACK32_SEGMENT
TopOfStack32Init equ Stack32SegLen - 1

; =============================================================
;                 Task A
; =============================================================
[section .task_a_ldt]
[bits 32]
;                                 段基址        段界限            段属性
TASK_A_LDT_ENTRY:
TASKA_DATA32_DESC  :  Descriptor   0,       TaskADataSegLen - 1,  DA_DR + DA_32
TASKA_STACK32_DESC :  Descriptor   0,       TaskAStackSegLen - 1, DA_DRW + DA_32
TASKA_CODE32_DESC  :  Descriptor   0,       TaskACodeSegLen - 1,  DA_C + DA_32

TaskLdtLen  equ  $ - TASK_A_LDT_ENTRY

;Selector
TaskAData32Selector    equ    (0x0000 << 3) + SA_TIL + SA_RPL0
TaskAStack32Selector   equ    (0x0001 << 3) + SA_TIL + SA_RPL0
TaskACode32Selector    equ    (0x0002 << 3) + SA_TIL + SA_RPL0

[section .task_a_data]
[bits 32]
TASK_A_DATA_SEGMENT:
	TASK_STRING         db "This is Task A", 0
	TASK_STRING_OFFSET  equ  TASK_STRING - $$
	
TaskADataSegLen  equ  $ - TASK_A_DATA_SEGMENT
	
[section .task_a_stack]
[bits 32]
TASK_A_STACK_SEGMENT:
	times 1024 db 0
	
TaskAStackSegLen  equ  $ - TASK_A_STACK_SEGMENT
TaskATopOfStack   equ  TaskAStackSegLen - 1

[section .task_a_code]
[bits 32]
TASK_A_CODE_SEGMENT:
	mov ax, VideoSelector
	mov gs, ax
	
	mov ax, TaskAStack32Selector
	mov ss, ax
	
	mov eax, TaskATopOfStack
	mov esp, eax
	
	mov ax, TaskAData32Selector
	mov ds, ax
	
	mov ebp, TASK_STRING_OFFSET
	mov dh, 12
	mov dl, 35
	mov bx, 0x0c
	call TaskAPrintString
	
	jmp Code16Selector : 0
	
TaskAPrintString:
	push cx
	push dx
	push eax
	push ebp
	push edi
TaskAprint:
	mov cl, [ds:ebp]
	cmp cl, 0
	je TaskAend
	
	mov eax, 80
	mul dh
	add al, dl
	shl eax, 1
	mov edi, eax
	mov ah, bl
	mov al, cl
	mov [gs:edi], ax
	
	inc ebp
	inc dl
	jmp TaskAprint
TaskAend:
	pop edi
	pop ebp
	pop eax
	pop dx
	pop cx
	ret	

	
TaskACodeSegLen  equ  $ - TASK_A_CODE_SEGMENT




	