%include "common.asm"

global _start


extern KMain
extern ClearScreen
extern InitInterrupt
extern EnableTimer
extern SendEIO
extern gIdtInfo
extern gGdtInfo
extern RunTask


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
	
	mov eax, dword [RunTaskEntry]
	mov [RunTask], eax
	
	mov eax, dword [IDTEntry]
	mov [gIdtInfo], eax
	mov eax, dword [IDTSize]
	mov dword [gIdtInfo + 4], eax
	
	
	mov eax, dword [InitInterruptEntry]
	mov [InitInterrupt], eax
	
	mov eax, dword [EnableTimerEntry]
	mov [EnableTimer], eax
	
	mov eax, dword [SendEIOEntry]
	mov [SendEIO], eax
	
	leave
	
	ret