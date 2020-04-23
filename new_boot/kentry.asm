%include "common.asm"

global _start


extern KMain
extern ClearScreen
extern gGdtInfo

[section .text]
_start:
	mov ebp, 0
	
	call InitGlobal
	
	call ClearScreen
	call KMain

	jmp $
	
InitGlobal:
	push ebp
	mov ebp, esp
	
	mov eax, dword [GDTEntry]
	mov [gGdtInfo], eax
	mov eax, dword [GDTSize]
	mov [gGdtInfo + 4], eax
	
	leave
	
	ret