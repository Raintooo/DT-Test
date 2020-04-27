
%include "blfunc.asm"
%include "common.asm"

org BaseOfLoader

Interface:
	BaseOfStack   equ  BaseOfLoader
	BaseOfTarget  equ  0xB000
	Target        db  "KERNEL"
	TargetLen     equ ($-Target)


[section .gdt]
; GDT definition                       段基址，           段界限，         段属性
GDT_ENTRY         :     Descriptor        0,                0,             0
CODE32_DESC       :     Descriptor        0,          Code32SegLen - 1,    DA_C  + DA_32 + DA_DPL0
VIDEO32_DESC      :     Descriptor    0xB8000,           0x07FFF ,         DA_DRWA  + DA_32 + DA_DPL0
CODE32_FLAT_DESC  :     Descriptor        0,             0xFFFFF	,      DA_C  + DA_32 + DA_DPL0
DATA32_FLAT_DESC  :     Descriptor        0,             0xFFFFF	,      DA_DRW  + DA_32 + DA_DPL0
TASK_LDT_DESC     :     Descriptor        0,                0,             0
TASK_TSS_DESC     :     Descriptor        0,                0,             0
; GDT end
GdtLen    equ   $ - GDT_ENTRY

GdtPtr:
          dw   GdtLen - 1
          dd   0 
		  
; GDT Selector
Code32Selector         equ (0x0001 << 3) + SA_TIG + SA_RPL0
Video32Selector        equ (0x0002 << 3) + SA_TIG + SA_RPL0
Code32FlatSelector     equ (0x0003 << 3) + SA_TIG + SA_RPL0
Data32FlatSelector     equ (0x0004 << 3) + SA_TIG + SA_RPL0

; end of [section .gdt]

[section .idt]
align 32
[bits 32]
IDT_ENTRY:
%rep 256
				Gate    Code32Selector,   DefaultHandlerLen,      0,  DA_386IGate + DA_DPL0
%endrep
IdtLen    equ  $ - IDT_ENTRY
IdtPtr:
          dw   IdtLen - 1
		  dd   0
		  
		  

TopOfStack16    equ 0x7c00


[section .s16]
[bits 16]
BLMain:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, SPInitValue
    
    ; initialize GDT for 32 bits code segment
    mov esi, CODE32_SEGMENT
    mov edi, CODE32_DESC
    
    call InitDescItem

    ; initialize GDT pointer struct
    mov eax, 0
    mov ax, ds
    shl eax, 4
    add eax, GDT_ENTRY
    mov dword [GdtPtr + 2], eax
	
	; initialize IDT pointer struct
	mov eax, 0
	mov ax, ds
	shl eax, 4
	add eax, IDT_ENTRY
	mov dword [IdtPtr + 2], eax
	
	call LoadTarget
	
	cmp dx, 0
	jz output
	

    ; 1. load GDT
    lgdt [GdtPtr]
	
	; load IDT
	lidt [IdtPtr]
    
	
	call StoreGlobal
    
    ; 2. close interrupt
    cli 
	
	; set IOPL to 3
	pushf
	pop  eax
	or   eax, 0x3000
	push eax
	popf
	
    
    ; 3. open A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al
    
    ; 4. enter protect mode
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax   
	
    ; 5. jump to 32 bits code
    jmp dword Code32Selector : 0
	
output:
	mov dx, 0
	mov bp, ErrStr
	mov cx, ErrLen
	call Print

    jmp $

; esi    --> code segment label
; edi    --> descriptor label
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
	
StoreGlobal:
	mov eax, dword [GdtPtr + 2]
	mov dword [GDTEntry], eax
	mov dword [GDTSize], GdtLen / 8
	
	mov eax, dword [IdtPtr + 2]
	mov dword [IDTEntry], eax
	mov dword [IDTSize], IdtLen / 8
	
	mov dword [RunTaskEntry], RunTask
	mov dword [InitInterruptEntry], InitInterrupt
	mov dword [EnableTimerEntry], EnableTimerFunc
	mov dword [SendEIOEntry], SendEIO
	
	ret
	
[section .gfunc]
[bits 32]
; Paramter --> Task* p
RunTask:
	push ebp
	mov ebp, esp          ;mov value in esp to ebp  
	
	mov esp, [ebp + 8]    ; store First Paramter
	
	lldt word [esp + 200] ; load ldt
	ltr  word [esp + 202] ; load tss
	
	pop gs
	pop fs
	pop es
	pop ds
	
	popad
	
	add esp, 4
	
	iret
;
;
InitInterrupt:
	push ebp
	mov ebp, esp
	
	push ax
    push dx
	
	call Init8259A
	
	sti
	
    mov al, 0xFF
	mov dx, MASTER_IMR_PORT
	call WriteIMR
	
	mov al, 0xFF
	mov dx, SLAVE_IMR_PORT
	call WriteIMR
	
	pop dx
    pop ax

	leave
	ret

;
;
EnableTimerFunc:
	push ebp
	mov ebp, esp

	push ax
	push dx

	
	mov dx, MASTER_IMR_PORT
	call ReadIMR
	
	and ax, 0xFE
	call WriteIMR
	
	pop dx
	pop ax
	
	leave
	
	ret
;
;paramter  --> port
SendEIO:
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + 8]
	mov al, 0x20
	out dx, al
	
	leave
	ret
	
[section .sfunc]
[bits 32]

Init8259A:
	push ax
	
	;master
	;ICW1
	mov al, 00010001B
	out MASTER_ICW1_PORT, al
	call Delay
	
	;ICW2
	mov al, 0x20
	out MASTER_ICW2_PORT, al
	call Delay
	
	;ICW3
	mov al, 00000100B
	out MASTER_ICW3_PORT, al
	call Delay
	
	;ICW4
	mov al, 00010001B
	out MASTER_ICW4_PORT, al
	call Delay
	
	;Slave
	;ICW1
	mov al, 00010001B
	out SLAVE_ICW1_PORT, al
	call Delay
	
	;ICW2
	mov al, 0x28
	out SLAVE_ICW2_PORT, al
	call Delay
	
	;ICW3
	mov al, 00000010B
	out SLAVE_ICW3_PORT, al
	call Delay
	
	;ICW4
	mov al, 00000001B
	out SLAVE_ICW4_PORT, al
	call Delay
	
	pop ax

	ret


; dx --> 8259A port
; return ax --> IMR register value
ReadIMR:
	in ax, dx
	call Delay
	ret
	
; al --> IMR register value
; dx --> 8259A port
WriteIMR:
	out dx, al
	call Delay
	ret

; dx --> 8259A port 
WriteEOI:
	push ax
	
	mov al, 0x20
	out dx, al
	call Delay
	
	pop ax
	ret

Delay:
	%rep 5
	nop
	%endrep
	ret

    
[section .s32]
[bits 32]
CODE32_SEGMENT:
	mov ax, Video32Selector
	mov gs, ax
	
	mov ax, Data32FlatSelector
	mov ds, ax
	mov es, ax
	mov fs, ax
	
	mov ax, Data32FlatSelector
	mov ss, ax
	
	mov esp, BaseOfLoader

    jmp dword Code32FlatSelector : BaseOfTarget
	
DefalutHandlerFunc:
	iret
DefaultHandlerLen      equ  DefalutHandlerFunc - $$

Code32SegLen   equ   $ - CODE32_SEGMENT

ErrStr db "KERNEL  not found!"
ErrLen equ ($-ErrStr)
Buf  db 0

