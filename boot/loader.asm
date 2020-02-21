org 0x9000

begin:
	mov si, msg
	
print:
	mov al, [si]
	add si, 1
	cmp al, 0x00
	je last
	mov dx, 0
	mov ah, 0x0e
	mov bx, 0x0f
	int 0x10
	jmp print
	
last:
	hlt
	jmp last

msg:
	db 0x0a, 0x0a
	db "Hello, DTOS!"
	db 0x0a, 0x0a
	db 0x00
	