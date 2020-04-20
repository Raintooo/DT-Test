
%include "common.asm"
%include "blfunc.asm"


org BaseOfBoot


Interface:
	BaseOfStack      equ BaseOfBoot
	BaseOfTarget     equ 0x9000
	Target db "LOADER"
	TargetLen equ ($-Target)

BLMain:
	mov ax, cs
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov sp, SPInitValue

	call LoadTarget
	cmp bx, 0
	jz output
	jmp BaseOfTarget


output:
	mov dx, 0
	mov bp, ErrStr
	mov cx, ErrLen
	call Print

    jmp $  
	


ErrStr db "LOADER was not found!"
ErrLen equ ($-ErrStr)

Buf:
	times 510-($-$$) db 0x00
	db 0x55, 0xaa
