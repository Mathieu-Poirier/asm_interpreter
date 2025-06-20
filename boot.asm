; boot.asm
; ================
; Two‐sector loader: sector 1 is this code, sectors 2–3 hold the continuation.

[BITS 16]
org 0x7C00

    ; ─── Save drive number ─────────────────────────────
    mov [BootDrive], dl

    ; ─── Setup segment registers ───────────────────────
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; ─── Load sectors 2 and 3 (two sectors) ────────────
    mov ah, 0x02        ; BIOS read sector
    mov al, 2           ; read 2 sectors
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; starting at sector 2
    mov dh, 0           ; head 0
    mov dl, [BootDrive] ; original drive
    mov bx, 0x7E00      ; ES:BX → 0x0000:0x7E00
    int 0x13
    jc disk_error       ; if carry set, jump to error

    ; ─── Jump into the now–loaded second stage at 0x0000:0x7E00 ───
    jmp 0x0000:0x7E00

; ─── Disk error handler ────────────────────────────────────────
disk_error:
    mov si, DiskErrMsg
.print_disk_err:
    lodsb
    or al, al
    jz $
    mov ah, 0x0E
    int 0x10
    jmp .print_disk_err

; ─── Data ──────────────────────────────────────────────────────
BootDrive:      db 0

DiskErrMsg:     db 'Disk read error!',0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
