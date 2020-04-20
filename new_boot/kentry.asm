
global _start


extern KMain
extern ClearScreen

[section .text]
_start:
	mov ebp, 0
	
	call ClearScreen
	call KMain

	jmp $
	