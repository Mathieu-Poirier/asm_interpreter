[BITS 16]
org 0x0000:0x7E00

mov ah,0
mov al,3
int 0x10
jmp TTY 

; Helper functions
get_cursor:
    mov ah,3
    xor bh,bh
    int 0x10
    ret

set_cursor:
    mov ah,2
    xor bh,bh
    int 0x10
    ret

print_hex_byte:
    push ax
    shr al, 4           ; high nibble
    call print_hex_digit
    pop ax
    and al, 0x0F        ; low nibble
    ; fall through
print_hex_digit:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    mov ah, 0x0E
    int 0x10
    ret

; Main loop to read from keyboard
TTY:
    xor ah,ah
    int 0x16
    cmp ah, 0x3D
    je save_video_memory
    cmp ah, 0x3E     
    je test_video_memory
    cmp al, 0x0D
    je new_line
    cmp ah, 0x39
    je space
    cmp al, 0x08
    je backspace
    cmp ah,0x4B
    je move_cursor_backward
    cmp ah, 0x4D
    je move_cursor_forward
    cmp ah, 0x48
    je move_cursor_up
    cmp ah, 0x50
    je move_cursor_down
    mov ah, 0x0E
    int 0x10
    jmp TTY

move_cursor_forward:
    call get_cursor
    cmp dl,79
    je  .set
    inc dl
.set:
    call set_cursor
    jmp TTY

move_cursor_backward:
    call get_cursor
    cmp dl,0
    je  .set
    dec dl
.set:
    call set_cursor
    jmp TTY

move_cursor_up:
    call get_cursor
    cmp dh,0
    je  .set
    dec dh
.set:
    call set_cursor
    jmp TTY

move_cursor_down:
    call get_cursor
    cmp dh,24
    je  .set
    inc dh
.set:
    call set_cursor
    jmp TTY

new_line:
    call get_cursor
    cmp dh,24
    je  .stay
    inc dh
.stay:
    xor dl,dl
    call set_cursor
    jmp TTY

space:
    call get_cursor
    push dx
    mov bl,dl
    xor bh,bh
    mov cl,dh
    cmp dl,79
    jne  .need_shift

    xor ax,ax
    mov al,cl
    mov cx,80
    mul cx
    add ax,bx
    shl ax,1
    mov di,ax
    mov ax,0xB800
    mov es,ax
    mov ax,[es:di]
    and ax,0xFF00
    or  ax,0x0020
    mov word [es:di],ax
    pop dx
    jmp  .set_cursor

.need_shift:
    xor ax,ax
    mov al,cl
    mov cx,80
    mul cx
    add ax,bx
    shl ax,1
    mov di,ax
    xor ax,ax
    mov al,cl
    mul cx
    add ax,78
    shl ax,1
    mov si,ax
    mov ax,0xB800
    mov es,ax

.copy_right:
    mov ax,[es:si]
    mov word [es:si+2],ax
    cmp si,di
    je  .insert_blank
    sub si,2
    jmp .copy_right

.insert_blank:
    mov ax,[es:di]
    and ax,0xFF00
    or  ax,0x0020
    mov word [es:di],ax
    pop dx
    inc dl
.set_cursor:
    call set_cursor
    jmp TTY

backspace:
    call get_cursor
    push dx
    mov bl,dl
    xor bh,bh
    cmp dl,0
    jne .shift_left
    xor bl,bl

.shift_left:
    xor ax,ax
    mov al,dh
    mov cx,80
    mul cx
    add ax,bx
    shl ax,1
    mov di,ax
    mov ax,0xB800
    mov es,ax
    xor ax,ax
    mov al,dh
    mul cx
    add ax,78
    shl ax,1
    mov si,ax

.shift_loop:
    mov dx,[es:di+2]
    mov word [es:di],dx
    add di,2
    cmp di,si
    jb  .shift_loop

    mov dx,[es:si]
    and dx,0xFF00
    or  dx,0x0020
    mov word [es:si],dx
    pop dx
    cmp dl,0
    je  .set_cur
    dec dl
.set_cur:
    call set_cursor
    jmp TTY

save_video_memory:
    xor ax, ax
    xor si, si
    ; copy from video memory [ds:si]
    mov ax, 0xB800
    mov ds, ax
    xor ax, ax
    mov ax, 0x2000
    mov es, ax
    xor ax, ax
    mov bx, 0x0000
.copy_video_to_memory:
    mov ax, [ds:si]     ; get ASCII char from video memory
    mov [es:bx], ax     ; store it into RAM buffer
    add si, 2           ; skip attribute byte
    inc bx
    cmp bx, 2000        ; stop after 2000 bytes (80×25)
    jne .copy_video_to_memory
    jmp save_video_memory_to_disk
    ; save to disk
save_video_memory_to_disk:
    xor ax, ax
    mov ah, 0x03
    mov al, 4
    mov ch, 0
    mov cl, 4
    mov dh, 0
    mov dl, 0
    int 0x13
    jmp TTY

test_video_memory:
    xor ax, ax
    mov es, ax
    xor si, si
    xor bx, bx
    xor di, di
    mov ds, ax

    ; TODO; read from sectors 4-7
    mov ah, 0x02        ; function: read
    mov al, 4           ; sectors to read
    mov ch, 0           ; cylinder
    mov cl, 4           ; sector (starting from 1)
    mov dh, 0           ; head
    mov dl, 0           ; drive (e.g., 0 for floppy)
    mov ax, 0x2000  
    mov es, ax          ; segment to store into
    xor bx, bx          ; offset 0
    int 13h
    ; TODO: Check some bytes
    mov si, 0
    mov cx, 8
.check_loop:
    mov al, [es:si]
    push cx
    call print_hex_byte
    pop cx
    inc si
    loop .check_loop
    jmp TTY

; ─── Data ──────────────────────────────────────────────────────


times 1024-($-$$) db 0

