%include "inc.asm"

org 0x9000

jmp ENTRY_SEGMENT

[section .gdt]
; GDT Definition
;                             段基址       段界限            段属性
GDT_ENTRY      :    Descriptor  0,           0,               0
CODE32_DES     :    Descriptor  0,         Code32SegLen-1,    DA_C    + DA_32 + DA_DPL1
VIDEO_DES      :    Descriptor  0xB8000,   0x7FFFF,           DA_DRWA + DA_32 + DA_DPL2
DATA32_DESC    :    Descriptor  0,         DataLength-1,      DA_DR   + DA_32 + DA_DPL2
STACK32_DESC   :    Descriptor  0,         TopOfStack32Init,  DA_DRW  + DA_32 + DA_DPL1
FUNCTION_DESC  :    Descriptor  0,         Func32SegLen-1,    DA_C    + DA_32 + DA_DPL1
TASKA_LDT_DESC :    Descriptor  0,         TaskLdtLen-1,      DA_LDT  + DA_DPL0
TSS_DESC       :    Descriptor  0,         TssSegLen-1,       DA_386TSS + DA_DPL0
NEW_DESC       :    Descriptor  0,         NewSegLen-1,       DA_CCO  + DA_32 + DA_DPL0  ;一致性代码段
; Gate
;                             选择子              偏移      参数个数    属性
;FUNC_CG_PRINT_DESC : Gate FunctionSelector,   CG_PRINT,     0,        DA_386CGate + DA_DPL3

GdtLen  equ  $ - GDT_ENTRY
GdtPtr:
	dw GdtLen - 1		;GDT界限
	dd 0				;GDT基地址 16位代码段中计算

;as pointer point to every descriptor's base address	
Code32Selector      equ  (0x0001 << 3) + SA_TIG + SA_RPL1
VideoSelector       equ  (0x0002 << 3) + SA_TIG + SA_RPL2
DataSelector        equ  (0x0003 << 3) + SA_TIG + SA_RPL2
Stack32Selector     equ  (0x0004 << 3) + SA_TIG + SA_RPL1
FunctionSelector    equ  (0x0005 << 3) + SA_TIG + SA_RPL1
TaskALdtSelector    equ  (0x0006 << 3) + SA_TIG + SA_RPL0
TssSelector         equ  (0x0007 << 3) + SA_TIG + SA_RPL0
NewSelector         equ  (0x0008 << 3) + SA_TIG + SA_RPL0
FuncCGPrintSelector equ  (0x0009 << 3) + SA_TIG + SA_RPL1
;end [section .gdt]

; =============================================================
;
;				      TSS
;
; =============================================================
[section .tss]
[bits 32]
TSS_SEGMENT:
		dd 0
		dd TopOfStack32Init    ;0
		dd Stack32Selector
		dd 0		          ;1
		dd 0
		dd 0                  ;2
		dd 0
		times 4*18 dd 0
		dw 0
		dw $ - TSS_SEGMENT + 2
		db 0xFF
		
TssSegLen   equ  $ - TSS_SEGMENT


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
	
;	mov [BACK_TO_REAL_MODE + 3], cs
	
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
	

	mov esi, FUNCTION_SEGMENT
	mov edi, FUNCTION_DESC
	call InitDescItem
	
	;Init ldt
	mov esi, TASK_A_LDT_ENTRY
	mov edi, TASKA_LDT_DESC
	call InitDescItem
	
	mov esi, TASK_A_CODE_SEGMENT
	mov edi, TASKA_CODE32_DESC
	call InitDescItem
	
	mov esi, TASK_A_DATA_SEGMENT
	mov edi, TASKA_DATA32_DESC
	call InitDescItem
	
	mov esi, TASK_A_STACK_SEGMENT
	mov edi, TASKA_STACK32_DESC
	call InitDescItem
	
	mov esi, TSS_SEGMENT
	mov edi, TSS_DESC
	call InitDescItem
	
	mov esi, NEW_SEGMENT
	mov edi, NEW_DESC
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
;	jmp dword Code32Selector : 0    ;通过选择子 获取对应段基址 再偏移0位
	push Stack32Selector
	push TopOfStack32Init
	push Code32Selector
	push 0
	retf
	
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
	

	
;	mov ax, TssSelector
;	ltr ax  ; load Tss
	
;	mov ax, TaskALdtSelector
;	lldt ax
	
;	push TaskAStack32Selector
;	push TaskATopOfStack
;	push TaskACode32Selector
;	push 0
;	retf
	
	jmp NewSelector : 0


	jmp $
Code32SegLen  equ  $ - CODE32_SEGMENT

[section .new]        
[bits 32]
NEW_SEGMENT:
	mov ebp, HELLO_OFFSET
	mov dh, 13
	mov dl, 35
	mov bx, 0x0c
	call FunctionSelector : CG_PRINT
	jmp $
NewSegLen   equ   $ - NEW_SEGMENT

; =============================================================
;
;			Global Functin Segment
;
; =============================================================
[section .func]
[bits 32]
FUNCTION_SEGMENT:

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
	retf
CG_PRINT  equ  PrintString - $$

Func32SegLen  equ $ - FUNCTION_SEGMENT


; =============================================================
;
;			Stack 32bits
;
; =============================================================
[section .gs]
[bits 32]
STACK32_SEGMENT:
	times 1024*4 db 0

Stack32SegLen equ  $ - STACK32_SEGMENT
TopOfStack32Init equ Stack32SegLen - 1




; =============================================================
;
;                 Task A Segment
;
; =============================================================
[section .task_a_ldt]
[bits 32]
;                                 段基址        段界限            段属性
TASK_A_LDT_ENTRY:
TASKA_CODE32_DESC  :  Descriptor   0,       TaskACodeSegLen - 1,  DA_C + DA_32 + DA_DPL3
TASKA_DATA32_DESC  :  Descriptor   0,       TaskADataSegLen - 1,  DA_DR + DA_32 + DA_DPL3
TASKA_STACK32_DESC :  Descriptor   0,       TaskAStackSegLen - 1, DA_DRW + DA_32 + DA_DPL3

TaskLdtLen  equ  $ - TASK_A_LDT_ENTRY

;Selector
TaskACode32Selector    equ    (0x0000 << 3) + SA_TIL + SA_RPL3
TaskAData32Selector    equ    (0x0001 << 3) + SA_TIL + SA_RPL3
TaskAStack32Selector   equ    (0x0002 << 3) + SA_TIL + SA_RPL3


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
	
	mov ax, TaskAData32Selector
	mov ds, ax
	
	mov ebp, TASK_STRING_OFFSET
	mov dh, 12
	mov dl, 35
	mov bx, 0x0c
	call FuncCGPrintSelector : 0
	
;	jmp Code16Selector : 0
	jmp $
	
TaskACodeSegLen  equ  $ - TASK_A_CODE_SEGMENT






	