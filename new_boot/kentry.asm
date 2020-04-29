%include "common.asm"

global _start
global TimerHandlerEntry

extern KMain
extern ClearScreen
extern InitInterrupt
extern EnableTimer
extern SendEIO
extern gIdtInfo
extern gGdtInfo
extern RunTask
extern TimerHandler
extern gCTaskAddr
extern LoadTask

%macro ISREntry 0
	; ss esp eflags cs eip were pushed when intterupt occured
	sub esp, 4 ; 
	
	pushad
	
	push ds
	push es
	push fs
	push gs
	
	mov esp, BaseOfLoader ; 0xa000
	
	call TimerHandler
%endmacro

%macro ISREnd 0
	mov esp, [gCTaskAddr]
	
	pop gs
	pop fs
	pop es
	pop ds
	
	popad
	
	
	add esp, 4
	
	iret  ; ss esp eflags cs eip were poped when intterupt finish
%endmacro

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
	
	mov eax, dword [LoadTaskEntry]
	mov [LoadTask], eax
	
	mov eax, dword [InitInterruptEntry]
	mov [InitInterrupt], eax
	
	mov eax, dword [EnableTimerEntry]
	mov [EnableTimer], eax
	
	mov eax, dword [SendEIOEntry]
	mov [SendEIO], eax
	
	leave
	
	ret
	
	
	
TimerHandlerEntry:

	ISREntry

	call TimerHandler

	ISREnd
	
	
	
	
	
	
	
	
	
	