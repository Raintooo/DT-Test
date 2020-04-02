%include "inc.asm"

org 0x9000

PageDirBase0    equ   0x200000
PageTblBase0    equ   0x201000
PageDirBase1    equ   0x700000
PageTblBase1    equ   0x701000

ObjAddr         equ   0x401000
PageTargetX     equ   0x501000
PageTargetY     equ   0x801000

jmp ENTRY_SEGMENT

[section .gdt]
; GDT definition
;                                       段基址，         段界限，       段属性
GDT_ENTRY         :     Descriptor        0,              0,             0
CODE32_DESC       :     Descriptor        0,        Code32SegLen - 1,    DA_C + DA_32
VIDEO_DESC        :     Descriptor     0xB8000,         0x07FFF,         DA_DRWA + DA_32
DATA32_DESC       :     Descriptor        0,        Data32SegLen - 1,    DA_DRW + DA_32
STACK32_DESC      :     Descriptor        0,         TopOfStack32,       DA_DRW + DA_32
PAGEDIR_DESC0     :     Descriptor    PageDirBase0,     4095,            DA_DRW + DA_32
PAGETBL_DESC0     :     Descriptor    PageTblBase0,     1023,            DA_DRW + DA_32 + DA_LIMIT_4K
PAGEDIR_DESC1     :     Descriptor    PageDirBase1,     4095,            DA_DRW + DA_32
PAGETBL_DESC1     :     Descriptor    PageTblBase1,     1023,            DA_DRW + DA_32 + DA_LIMIT_4K
FLAT_MODE_RW_DESC :     Descriptor        0,            0xFFFFF,         DA_DRW + DA_32 + DA_LIMIT_4K
; GDT end

GdtLen    equ   $ - GDT_ENTRY

GdtPtr:
          dw   GdtLen - 1
          dd   0
          
          
; GDT Selector

Code32Selector     equ (0x0001 << 3) + SA_TIG + SA_RPL0
VideoSelector      equ (0x0002 << 3) + SA_TIG + SA_RPL0
Data32Selector     equ (0x0003 << 3) + SA_TIG + SA_RPL0
Stack32Selector    equ (0x0004 << 3) + SA_TIG + SA_RPL0
PageDirSelector0   equ (0x0005 << 3) + SA_TIG + SA_RPL0
PageTblSelector0   equ (0x0006 << 3) + SA_TIG + SA_RPL0
PageDirSelector1   equ (0x0007 << 3) + SA_TIG + SA_RPL0
PageTblSelector1   equ (0x0008 << 3) + SA_TIG + SA_RPL0
FlatModeRWSelector equ (0x0009 << 3) + SA_TIG + SA_RPL0
; end of [section .gdt]

TopOfStack16    equ 0x7c00

[section .dat]
[bits 32]
DATA32_SEGMENT:
    DTOS               db  "D.T.OS!", 0
	DTOS_LEN           equ $ - DTOS
    DTOS_OFFSET        equ DTOS - $$
    HELLO_WORLD        db  "Hello World!", 0
	HELLO_LEN          equ $ - HELLO_WORLD
    HELLO_WORLD_OFFSET equ HELLO_WORLD - $$

Data32SegLen equ $ - DATA32_SEGMENT

[section .s16]
[bits 16]
ENTRY_SEGMENT:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, TopOfStack16
    
    ; initialize GDT for 32 bits code segment
    mov esi, CODE32_SEGMENT
    mov edi, CODE32_DESC
    
    call InitDescItem
    
    mov esi, DATA32_SEGMENT
    mov edi, DATA32_DESC
    
    call InitDescItem
    
    mov esi, STACK32_SEGMENT
    mov edi, STACK32_DESC
    
    call InitDescItem
    
    ; initialize GDT pointer struct
    mov eax, 0
    mov ax, ds
    shl eax, 4
    add eax, GDT_ENTRY
    mov dword [GdtPtr + 2], eax

    ; 1. load GDT
    lgdt [GdtPtr]
    
    ; 2. close interrupt
    cli 
    
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

    
[section .s32]
[bits 32]
CODE32_SEGMENT:   
    mov ax, VideoSelector
    mov gs, ax
    
    mov ax, Stack32Selector
    mov ss, ax
    
    mov eax, TopOfStack32
    mov esp, eax
	
    mov ax, Data32Selector
    mov ds, ax
    
    mov ebp, DTOS_OFFSET
    mov bx, 0x0C
    mov dh, 12
    mov dl, 33
    
    call PrintString
	
	mov eax, PageDirSelector1
	mov ebx, PageTblSelector1
	mov ecx, PageTblBase1
	call InitPageTable		
	
	mov eax, PageDirSelector0
	mov ebx, PageTblSelector0
	mov ecx, PageTblBase0
	call InitPageTable

    
    mov ebp, HELLO_WORLD_OFFSET
    mov bx, 0x0C
    mov dh, 13
    mov dl, 31
	call PrintString
	
	mov ax, FlatModeRWSelector
	mov es, ax
	mov esi, DTOS_OFFSET
	mov ecx, DTOS_LEN
	mov edi, PageTargetX
	call MemCpy32
	
	mov ax, FlatModeRWSelector
	mov es, ax
	mov esi, HELLO_WORLD_OFFSET
	mov edi, PageTargetY
	mov ecx, HELLO_LEN
	call MemCpy32
	
	
	mov eax, ObjAddr
	mov ebx, PageTargetX
	mov ecx, PageDirBase0
	call MapAddress
	
	
	mov eax, ObjAddr
	mov ebx, PageTargetY
	mov ecx, PageDirBase1
	call MapAddress

    jmp $
	
; es   --> flat mode
; eax  --> virtual address
; ebx  --> target address
; ecx  --> page dirctory base
MapAddress:
	push edi
	push es
	push eax
	push ebx ;[esp + 4]
	push ecx ;[esp]

	; 1.取虚地址高10位, 获取子页表在页目录中位置
	mov eax, [esp + 8]
	shr eax, 22
	and eax, 0x3F
	shl eax, 2
	
	; 2.取虚地址中10位, 获取物理页在子页表的位置
	mov ebx, [esp + 8]
	shr ebx, 12
	and ebx, 0x3F
	shl ebx, 2
	
	; 3.获取子页表起始地址
	mov esi, [esp]
	add esi, eax
	mov edi, [es:esi]
	and edi, 0xFFFFF000
	
	; 4.将目标地址写入子页表对应位置
	add edi, ebx
	mov ecx, [esp + 4]
	and ecx, 0xFFFFF000
	or  ecx, PG_P | PG_USU | PG_RWW
	mov [es:edi], ecx
	
	pop ecx
	pop ebx
	pop eax
	pop es
	pop edi
	
	ret
	
; es     --> flat mode
; ds:esi --> source
; es:edi --> destinition
; ecx    --> length
MemCpy32:
	push esi
	push edi
	push ecx
	push es
	
	cmp esi, edi
	ja btoe
	
	add esi, ecx
	add edi, ecx
	dec edi
	dec esi
	jmp etob
	
btoe:
	cmp ecx, 0
	je done

	mov al, [ds:esi]
	mov byte [es:edi], al
	dec ecx
	inc esi
	inc edi
	jmp btoe

etob:
	cmp ecx, 0
	je done

	mov al, [ds:esi]
	mov byte [es:edi], al
	dec ecx
	dec esi
	dec edi
	jmp etob	

done:
	pop es
	pop ecx
	pop edi
	pop esi

	ret

; eax --> Page dir base selector
; ebx --> Page table base selector
; ecx --> Page table base
InitPageTable:
	push eax  ;[esp + 16]
	push ebx  ;[esp + 12]
	push ecx  ;[esp + 8]
	push edi  ;[esp + 4]
	push es   ;[esp ]
	
	mov ecx, 1024
	mov es, ax
	mov edi, 0
	mov eax, [esp + 8]
	or  eax, PG_P | PG_USU | PG_RWW
	
	cld
SetDir:
	stosd
	add eax, 4096
	loop SetDir
	
	mov ecx, 1024*1024
	mov ax, [esp + 12]
	mov es, ax
	mov edi, 0
	mov eax, PG_P | PG_USU | PG_RWW
	
	cld
SetTbl:
	stosd
	add eax, 4096
	loop SetTbl
	
	pop es
	pop edi
	pop ecx
	pop ebx
	pop eax
	
	ret

; eax --> Page dir base
SwitchPageTable:	
	push eax

	mov eax, cr0
	and eax, 0x7FFFFFFF
	mov cr0, eax
	
	mov eax, [esp]
	mov cr3, eax
	mov eax, cr0
	or  eax, 0x80000000
	mov cr0, eax

	pop eax
	
	ret
	

; ds:ebp    --> string address
; bx        --> attribute
; dx        --> dh : row, dl : col
PrintString:
    push ebp
    push eax
    push edi
    push cx
    push dx
    
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
    pop dx
    pop cx
    pop edi
    pop eax
    pop ebp
    
    ret
    
Code32SegLen    equ    $ - CODE32_SEGMENT

[section .gs]
[bits 32]
STACK32_SEGMENT:
    times 1024 * 4 db 0
    
Stack32SegLen equ $ - STACK32_SEGMENT
TopOfStack32  equ Stack32SegLen - 1