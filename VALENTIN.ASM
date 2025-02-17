.model tiny

.data

argc  dw 0
argv  dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;max 7 arg command line 
; argv is array struct ptr_str + size_str


FrameStyle      db 218, 196, 191, 179, 32, 179, 192, 196, 217
                db 201, 205, 187, 186, 32, 186, 200, 205, 188 
                db '_________'
                db '+++++++++'
                db '---------'
                db '<=>< ><=>'
				db ',,,,,,,,,'
                db '.........'

LenghtScreen    dw 00a0h
FrameIndent     dw 5
SizeStrStyle    dw 3
SizeStyle       dw 9
NumberStyle     dw 7

.code

org 100h

main:
	cld
	call command_processing_for_DOS

	mov bx, 0b800h
	mov es, bx
	call processing_param_command_line
	call print_animation
	mov ax, 4c00h
	int 21h

;_____________________________________
;Exit: None
;Exit: Initialize register for print_animation
;Destr: ax, bx, cx, dx, si, di, bp
;_____________________________________
processing_param_command_line proc
	mov bx, offset argv
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	call strtol
	mov dx, bp
	mov al, dl

	mov bx, offset argv + 4
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	push ax
	call strtol

	pop ax
	mov dx, bp
	mov ah, dl

	mov bx, offset argv + 8
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	mov bx, si

	push ax
	push bx
	push cx

	mov bx, offset argv + 12
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	mov bx, si
	call give_adress_framestyle
	mov si, ax
	push si

	mov bx, offset argv + 16
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	mov bx, si
	call strhex

	mov di, bp

	mov bx, offset argv + 20
	mov si, [bx]
	add bx, 2
	mov cx, [bx]
	mov bx, si
	call strhex

	mov dx, bp

	pop si
	pop cx
	pop bx
	pop ax

	ret
	endp


;_______________________________
;Exit: si = adress str
;      cx = size str
;Exit: ax = adress FrameStyle
;Destr: bx, cx, dx, si
;_______________________________
give_adress_framestyle proc
	call strtol
	xor ax, ax
	mov bx, [NumberStyle]

	cmp bp, ax
	js end_give_adress_framestyle

	cmp bx, bp
	js end_give_adress_framestyle

	mov ax, [SizeStyle]
	mov dx, bp	
	mul dx

	add ax, offset FrameStyle
	ret

	end_give_adress_framestyle:
		mov bx, offset argv
		add bx, 24
		mov ax, [bx]
		ret
	
	endp

	

;_______________________________
;Exit: si = adress str
;      cx = size str
;Exit: bp = number
;Destr: ax, bx, cx, dx, si
;_______________________________
strhex       proc
	xor bp, bp
	xor ax, ax
	inc ax
	
	add si, cx
	dec si
	std

	L1_strhex:
		mov dx, ax
		lodsb
		mov bx, ax
		mov ax, dx
		
		mov bh, 29h
		cmp bl, bh
		js check_is_big_alpha

		mov bh, 3ah
		cmp bh, bl
		js check_is_big_alpha

		sub bl, 30h
	
		jmp end_check_hex
	
		check_is_big_alpha:
		mov bh, 40h
		cmp bl, bh
		js check_is_alpha
		
		mov bh, 47h
		cmp bh, bl
		js check_is_alpha

		sub bl, 37h
		jmp end_check_hex

		check_is_alpha:
		mov bh, 60h
		cmp bl, bh
		js end_strhex

		mov bh, 67h
		cmp bh, bl
		js end_strhex

		sub bl, 57h

		end_check_hex:
		xor bh, bh

		push ax
		mul bx
		add bp, ax
		pop ax
		
		shl ax, 4
	
		loop L1_strhex
	
	end_strhex:
	cld
	ret
	endp


;Exit: si = adress str
;      cx = size str
;Exit: bp = number
;Destr: ax, bx, cx, dx, si
;_______________________________
strtol         proc
	xor bp, bp
	xor ax, ax
	inc ax

	add si, cx
	dec si
	std

	L1_strtol:
		mov dx, ax
		lodsb
		mov bx, ax
		mov ax, dx
		
		mov bh, 29h
		cmp bl, bh
		js end_strtol

		mov bh, 3ah
		cmp bh, bl
		js end_strtol

		sub bl, 30h
		xor bh, bh
		
		push ax
		mul bx
		add bp, ax
		pop ax
		
		mov dx, ax
		shl ax, 1
		shl dx, 3
		add ax, dx
		loop L1_strtol
	 

	end_strtol: 
	
	cld
	ret
	endp

;_______________________________
;Entry: None
;Exit: Initialize argv and argc
;Destr: bp, cx, ax, bx, dx, di, si
;_______________________________
command_processing_for_DOS proc
	mov si, 0081h
	mov cl, ds:[80h]
	call command_processing
	ret
	endp

;_______________________________
;Entry: si = begin command line
;       cx = size command line
;Exit: Initialize argv and argc
;Destr: bp, cx, ax, bx, dx, di, si
;_______________________________
command_processing proc
	xor bp, bp
	mov di, offset argv

	L1_command_processing:
		call skip_spaces
		mov bx, di
		add bx, bp
		mov [bx], si
		
		inc bp
		inc bp
		
		inc cx
		call skip_not_spaces
		mov bx, di
		add bx, bp
		mov [bx], dx
		inc bp
		inc bp
		
		loop L1_command_processing 
	 
	shr bp, 2
	mov [argc], bp
	ret
	endp

;_______________________________
;Entry: si = adress string
;       cx = max lenght string
;Exit   si = adress char spaces
;       dx = lenght not spaces char
;Destr  ax, cx, bl
;_______________________________
skip_not_spaces proc
	xor dx, dx
	L1_skip_not_spaces:
		lodsb
		inc dx
		call is_spaces
		loopnz L1_skip_not_spaces
	
	dec dx
	dec si
	inc cx
	ret
	endp

;_______________________________
;Entry: si = adress string
;       cx = max lenght string
;Exit:  si = adress char not spaces
;       dx = lenght spaces char
;Destr: ax, cx, bl 
;_______________________________
skip_spaces     proc
	xor dx, dx
	L1_skip_spaces:
		lodsb
		inc dx
		call is_spaces
		loopz L1_skip_spaces

	dec dx
	dec si
	inc cx
	ret 
	endp
		
;_______________________________
;Entry: al = symbol
;Exit:  ZF = 1 if al is spaces
;Destr: bl
;_______________________________
is_spaces       proc
	mov bl, 09h
	cmp al, bl
	je good_symbol
	
	mov bl, 0ah
	cmp al, bl
	je good_symbol
	
	mov bl, 0dh
	cmp al, bl
	je good_symbol

	mov bl, 20h
	cmp al, bl
	je good_symbol
	
	ret

	good_symbol:  
		cmp al, al
		ret
	
	endp 


;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       cx = size string
;       si = frame style
;       bx = adress str
;       dl = color str
;       di = color frame
;Exit: None
;Destr: ax, bx, dx, di, bp
;_______________________________
print_animation proc
	push dx
	push bx
	push cx
	mov bp, [FrameIndent]
	xor dx, dx 

	jmp cond_print_cadr
	
	cycle_cadr:
		push ax

		push cx
		push dx
		
		call give_offset
		pop dx
		pop cx
		
		push cx
		push dx
		push si
		push di
		mov bx, di
		xor bh, bh
		call print_frame
		pop di
		pop si
		
		
		mov ax, 8600h
		mov cx, 0010h
		xor dx, dx
		int 15h
		pop dx
		pop cx
		
		inc cx
		inc dx
		pop ax
	cond_print_cadr:
		cmp dx, bp
		jb cycle_cadr

	pop cx
	pop bx
	mov si, bx
	pop dx
	mov dh, dl
	call print_central_str

	ret
	endp

;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       cx = size str
;       si = adress str
;       dh = color
;Exit: None
;Descr: ax, cx, si, di
;_______________________________
print_central_str proc
	push bx
	push cx
	push dx
	xor dx, dx
	call give_offset
	call give_adress
	pop dx
	pop cx
	pop bx

	mov ah, dh
	xor dx, dx
	cmp dx, cx
	je end_printed

	printed_str:
		lodsb
		stosw
		loop printed_str
	end_printed:

	ret
	endp
		
;_______________________________
;Entry: ah = x coordinate
;       al = y coordinate
;       cx = horisontale size
;       dx = verticale size
;Exit:  ah = horisontale offset
;       al = verticale offset
;Destr: cx, dx
;_______________________________
give_offset     proc
	shr cx, 1
	shr dx, 1
	sub al, dl
	sub ah, cl 
	ret
	endp
	
;_______________________________
;Entry: ah = horisontale offset
;       al = verticale offset
;       cx = horisontale size
;       dx = verticale size
;       bl = color
;       si = frame style
;Exit:  None
;Destr: ax, dx, cx, si, di
;_______________________________
print_frame     proc
	push bx
	push dx
	call give_adress
	pop dx
	pop bx

	push di
	push cx
	call print_str
	pop cx
	pop di

	add di, [LenghtScreen]

	jmp cond_print_frame1
	xor dx, dx
	
	cycle_print_frame1:
		push cx
		push di
		call print_str
		sub si, [SizeStrStyle]
		pop di
		pop cx
		
		add di, [LenghtScreen]
		dec dx
	
	cond_print_frame1:
		xor ax, ax
		cmp ax, dx
		jb cycle_print_frame1

	add si, [SizeStrStyle]
	call print_str	
	ret
	endp

;_______________________________
;Entry: ah = horisontale offset
;	al = verticale offset                                                   
;Exit:  di = start_adress
;Destr: dx, ax, bx
;_______________________________
give_adress     proc
	mov bx, ax
	mov dx, [LenghtScreen]
	mul dl
	mov di, ax

	mov ax, bx
	shr ax, 7
	add di, ax

	ret	
	endp

;_______________________________
;Entry: si = frame_style
;       di = adress_video_memory
;       cx = lenght
;	bl = color
;Exit:  None
;Destr: cx, si, di
;_______________________________ 
print_str	proc
	lodsb
	mov ah, bl
	stosw
	
	lodsb
	rep stosw
	
	lodsb 
	stosw
	ret
	endp
		
end main
	