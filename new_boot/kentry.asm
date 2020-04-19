
global _start


extern KMain

[section .text]
_start:
	mov ebp, 0
	
	call KMain

	jmp $
	