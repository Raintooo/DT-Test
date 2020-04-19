
global _start
global print
global vstr
global len

extern c_func

[section .data]
	vstr       db      "Hello guys !", 0x0A
	len        dd     $ - vstr

[section .text]
_start:
	mov ebp, 0
	
	call c_func
	call exit
	
	
print:
	push ebp
	mov ebp, esp
	
	mov edx, [ebp + 12]
	mov ecx, [ebp + 8]
	
	mov ebx, 1
	mov eax, 4
	int 0x80
	
	pop ebp
	ret
	
exit:
	mov ebx, 0
	mov eax, 1
	int 0x80