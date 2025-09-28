bits 16
org 0x7C00

start:
    ; Disable interrupts
    cli
    
    ; Set up segments
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Set up stack
    mov ax, 0x0000
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Clear screen
    mov ax, 0x0003
    int 0x10
    
    ; Print loading message
    mov si, loading_msg
    call print_string
    
    ; Load kernel from disk (sector 2)
    mov ah, 0x02        ; Read sectors
    mov al, 10          ; Number of sectors to read (10 sectors = 5KB)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2 (boot sector is sector 1)
    mov dh, 0           ; Head 0
    mov dl, 0x80        ; Drive 0x80 (first HDD)
    mov bx, 0x7E00      ; Load at 0x7E00 (right after bootloader)
    int 0x13
    
    jc disk_error       ; Jump if error
    
    ; Jump to kernel
    jmp 0x7E00

disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E
.print_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_loop
.done:
    ret

loading_msg db "Booting M4CH1N3 OS by execRooted...", 0x0D, 0x0A, 0
error_msg db "Disk read error! Press any key to reboot.", 0x0D, 0x0A, 0

; Fill rest of boot sector and add boot signature
times 510-($-$$) db 0
dw 0xAA55
