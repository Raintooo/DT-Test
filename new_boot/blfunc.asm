jmp short _start
nop
 
header : 
    BS_OEMName     db "D.T.Soft"
    BPB_BytsPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RsvdSecCnt dw 1
    BPB_NumFATs    db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16   dw 2880
    BPB_Media      db 0xF0
    BPB_FATSz16    dw 9
    BPB_SecPerTrk  dw 18
    BPB_NumHeads   dw 2
    BPB_HiddSec    dd 0
    BPB_TotSec32   dd 0
    BS_DrvNum      db 0
    BS_Reserved1   db 0
    BS_BootSig     db 0x29
    BS_VolID       dd 0
    BS_VolLab      db "D.T.OS-0.01"
    BS_FileSysType db "FAT12   "
	
const:
	SPInitValue      equ BaseOfStack - EntryLen
	EntryItem        equ SPInitValue  
	RootEntryOffset  equ 19
	RootEntryLength  equ 14
	RootEntCnt       equ 224
	EntryLen         equ 32
	FatEntryLength   equ 9
	FatEntryOffset   equ 1

_start:
	jmp BLMain
	
; return  dx --> 1 : success  0 : failed 
LoadTarget:
		;read root dir to buf
	mov cx, RootEntryLength
	mov ax, RootEntryOffset
	mov bx, Buf
	call ReadFloopy		

	;find specified file
	mov dx, 0
	mov si, Target
	mov cx, TargetLen
	call FindEntry
	
	cmp dx, 0
	jz finish
	
	;copy root dir to EntryItem
	;bx was changed in FindEntry, so bx pointed to the specified file node
	mov si, bx		
	mov di, EntryItem
	mov cx, EntryLen
	call MemoryCopy
	
	;read fat table
	mov ax, FatEntryLength
	mov cx, [BPB_BytsPerSec]
	mul cx
	mov bx, BaseOfTarget
	sub bx, ax
	mov ax, FatEntryOffset
	mov cx, FatEntryLength
	call ReadFloopy
	
	mov dx, [EntryItem + 0x1A] ;0x1a means DIR_FstClus
	mov si, BaseOfTarget/0x10
	mov es, si
	mov si, 0
	
loading:	
	mov ax, dx
	add ax, 31
	mov cx, 1     
	push dx
	push bx		;save fat table address
	mov bx, si    
	call ReadFloopy
	pop bx	     ;get fat table address from stack
	pop cx       ; ==> pop dx   mov cx, dx
	
	call FatVec  ;dx changed in FatVec 
	cmp dx, 0xFF7
	jnb finish  ;success and return 
	
	add si, 512
	cmp si, 0
	jnz continue
	mov si, es
	add si, 0x1000
	mov es, si
	mov si, 0
continue:
	jmp loading
	
finish:
	ret
	
Print :
	mov ax, 0x1301
	mov bx, 0x0007
	
	int 0x10
	ret
	
ResetFloopy :
	push ax
	mov ah, 0x00
	mov dl, [BS_DrvNum]
	
	int 0x13
	
	pop ax
	ret

;cx    -->numbers of sector
;ex:bx -->target address
;ax    -->logic sector number
ReadFloopy :
	call ResetFloopy
	
	push bx
	push cx		;save numbers of sector
	
	mov bl, [BPB_SecPerTrk]
	div bl
	
	mov dh, al
	and dh, 1
	
	mov ch, al
	shr ch, 1
	
	mov cl, ah
	add cl, 1
	
	pop ax    ;get number of sector to ax
	pop bx
	mov dl, [BS_DrvNum]
	
	mov ah, 0x02

read:
	int 0x13
	jc read
	
	ret

;ds:si --> source 
;es:di --> destination
;cx    --> length
MemoryCmp:

compare:
	cmp cx, 0
	jz equal
	
	mov al, [si]
	cmp al, byte [di]
	jz goon
	jmp noequal
goon:
	inc si
	inc di
	dec cx
	jmp compare
	
equal:
noequal:

	ret

;ds:si --> source 
;es:di --> destination
;cx    --> length
MemoryCopy:
	
	cmp si, di
	ja btoe
	
	add si, cx
	add di, cx
	dec si
	dec di
	jmp etob
	
btoe:
	cmp cx, 0
	jz done
	
	mov al, [si]
	mov byte [di], al
	inc di
	inc si
	dec cx
	jmp btoe
	
etob:	
	cmp cx, 0
	jz done
	
	mov al, [si]
	mov byte [di], al
	dec di
	dec si
	dec cx
	jmp etob

done:

	ret

;es:bx  --> root entry offset address
;ds:si  --> target string 
;cx     --> string length 
;  return dx  
;   dx > 0 ? exit : noexit
FindEntry:
	push di
	push bp
	push cx
	
	mov dx, [BPB_RootEntCnt]
	mov bp, sp
find:
	cmp dx, 0
	jz noexit
	
	mov di, bx
	mov cx, [bp]
	call MemoryCmp
	
	cmp cx, 0
	jz exit
	dec dx
	add bx, 32  ;sizeof(header)
	jmp find
	
exit:	
noexit:
	pop cx
	pop bp
	pop di
	ret
	
;cx  --> index
;bx  --> fat table address
; return dx --> fat[index]
FatVec:
	push cx

	mov ax, cx
	shr ax, 1
	
	mov ah, 0
	mov cx, 3
	mul cx
	mov cx, ax
	
	pop ax
	and ax, 0x1
	jz even
	jmp odd
	
even:  ; FatVec[j] = ( (Fat[i+1] & 0x0F) << 8 ) | Fat[i];
	mov dx, cx
	add dx, 1
	add dx, bx
	
	mov bp, dx
	mov dl, byte [bp]   ;Fat[i+1] 
	and dl, 0x0F		;& 0x0F
	shl dx, 8
	
	add cx, bx
	mov bp, cx		;Fat[i]
	or dl, byte [bp] 
	jmp return
	
odd:  ; FatVec[j+1] = (Fat[i+2] << 4) | ( (Fat[i+1] >> 4) & 0x0F );
	mov dx, cx
	add dx, 2
	add dx, bx
	
	mov bp, dx
	mov dl, byte [bp]
	mov dh, 0
	shl dx, 4		;(Fat[i+2] << 4)
	
	add cx, 1
	add cx, bx
	mov bp, cx
	mov cl, byte [bp]
	mov ch, 0
	shr cx, 4
	and cx, 0x0F	;Fat[i+1] >> 4) & 0x0F 
	
	or dx, cx
return:
	ret