.model tiny
.code

org 100h

main:
	mov bx, 0b800h
	mov es, bx

	mov ax, 2010h
	mov bp, offset EndString
	sub bp, offset StartString
	mov bh, 02h
	mov si, offset FrameStyle
	mov di, offset StartString 
	call print_animation
	mov ax, 4c00h
	int 21h


;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       bp = size string
;       si = frame style
;       di = adress str
;       bh = color str
;Exit: None
;Destr: ax, bx, dx, di, bp
;_______________________________
print_animation proc
	push bx
	push di
	push bp

	mov cx, bp
	mov ch, cl
	mov cl, 01h
	mov dx, bp
	add bp, 06h
	push dx
	push ax
	push si	
	
	jmp cond_print_animation1
	
	cycle_print_animation1:
		call give_offset
		pop si
		call print_frame
		pop ax
		pop dx
		add cl, 01h
		add ch, 01h
		add dx, 01h
		push dx
		push ax
		push si
		
		push cx
		push ax
		push dx
		mov ax, 8600h
		mov cx, 0010h
		mov dx, 0ffffh
		int 15h
		pop dx
		pop ax
		pop cx

	cond_print_animation1:
		cmp dx, bp
		jb cycle_print_animation1
	

	pop si
	pop ax
	pop dx

	pop bp
	pop di
	pop bx
	call print_central_str
	ret
	endp

;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       bp = size str
;       di = adress str
;       bh = color
;Exit: None
;Descr: ax, bx, cx, dx
;_______________________________
print_central_str proc
	push bx
	mov bx, ax
	mov ax, bp
	mov dl, 02h
	div dl
	sub bh, al
	mov ax, bx
	
	push di
	call give_adress
	pop di
	pop cx

	mov ah, ch
	mov dx, 0000h
	
	jmp cond_print_central_str1
	
	cycle_print_central_str1:
		mov al, [di]
		call print_letter
		
		add bx, 0002h
		add di, 0001h
		add dx, 0001h
	
	cond_print_central_str1:
		cmp dx, bp
		jb cycle_print_central_str1

	ret
	endp
		
;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       ch = horisontale size
;       cl = verticale size
;Exit:  ah = horisontale offset
;       al = verticale offset
;Destr: dl, si, bx
;_______________________________
give_offset     proc
	mov si, ax
	mov dl, 02h
 
	mov ax, 0000h
	mov al, cl
	div dl
	mov bl, al

	mov ax, 0000h
	mov al, ch
	div dl
	mov bh, al
	
	mov ax, si 

	sub al, bl
	sub ah, bh
	ret
	endp
	

;_______________________________
;Entry: ah = horisontale offset
;       al = verticale offset
;       ch = horisontale size
;       cl = verticale size
;       si = frame style
;Exit:  None
;Destr: dx, di, bx, ax
;_______________________________
print_frame     proc
	call give_adress
	mov di, bx
	call print_str

	add si, 0006h
	mov bx, di
	add bx, 00a0h
	add di, 00a0h

	mov dl, 0000h
	jmp cond_print_frame1
	
	cycle_print_frame1:
		call print_str
		mov bx, di
		add bx, 00a0h
		add di, 00a0h
		add dl, 01h
	
	cond_print_frame1:
		cmp dl, cl
		jb cycle_print_frame1

	add si, 0006h
	call print_str
	sub si, 000ch	
	ret
	endp

;_______________________________
;Entry: ah = horisontale offset
;	al = verticale offset                                                   
;Exit:  bx = start_adress
;Destr: di, dx, ax
;_______________________________
give_adress     proc
	mov di, ax
	mov dx, 00a0h
	mul dl
	mov bx, ax

	mov ax, di
	mov al, ah
	mov dl, 02h
	mul dl
	add bx, ax

	ret	
	endp 
	
;_______________________________
;Entry: ah = color
;       al = symbol
;       bx = adress_video_memory
;Exit:  None
;Destr: None
;_______________________________
print_letter   	proc
	mov es:[bx], ax
	ret
	endp

;_______________________________
;Entry: si = adress_format
;       bx = adress_video_memory
;       ch = lenght
;Exit:  None
;Destr: bx, dh
;_______________________________ 
print_str	proc
	mov ax, [si]
	call print_letter
	
	add bx, 0002h
	mov ax, [si+2]
	call print_rep_char

	mov ax, [si+4]
	call print_letter
	
	ret
	endp

;_______________________________
;Entry: ax = color and symbol
;       bx = adress_video_memory
;       ch = lenght
;Exit:  None
;Destr: dh, bx
;_______________________________
print_rep_char	proc
	mov dh, 00h
	jmp cond_print_rep_char1

	cycle_rep_char1:
		call print_letter
		add dh, 01h
		add bx, 0002h

	cond_print_rep_char1:
		cmp dh, ch
		jb cycle_rep_char1
	
	ret
	endp

.data
FrameStyle      db 41h, 01h, 42h, 01h, 43h, 01h
		db 44h, 01h, 45h, 01h, 46h, 01h
		db 47h, 01h, 48h, 01h, 49h, 01h

StartString     db 'Hello world, my dear friend'
EndString:
		
end main
	