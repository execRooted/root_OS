bits 16
org 0x7E00

start:
    ; Set video mode to text mode
    mov ax, 0x0003
    int 0x10
    
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    ; Set cursor position to top
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10
    
    ; Initialize file system with default files
    call init_filesystem
    
    ; Print welcome message
    mov si, welcome_msg
    call print_string
    
    ; Start shell
    jmp shell

; Initialize file system with default files
init_filesystem:
    ; Create boot.bin file entry
    mov di, file_entries
    mov si, file_boot_bin
    call copy_string
    add di, 32
    mov dword [di], 512    ; file size
    add di, 4
    mov dword [di], 0x7C00 ; file location
    
    ; Create kernel.bin file entry
    mov di, file_entries + 64
    mov si, file_kernel_bin
    call copy_string
    add di, 32
    mov dword [di], 5120   ; file size
    add di, 4
    mov dword [di], 0x7E00 ; file location
    
    ret

; Print string function
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

; Print new line
print_newline:
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    ret

; Copy string from SI to DI
copy_string:
.copy_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_loop
    ret

; Main shell
shell:
    call print_newline
    mov si, prompt
    call print_string
    
    ; Read input
    mov di, input_buffer
    mov cx, 0
.read_loop:
    mov ah, 0x00
    int 0x16
    
    ; Check for enter key
    cmp al, 0x0D
    je .process_input
    
    ; Check for backspace
    cmp al, 0x08
    je .backspace
    
    ; Check if buffer is full
    cmp cx, 63
    jge .read_loop
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    ; Store character
    stosb
    inc cx
    jmp .read_loop

.backspace:
    cmp cx, 0
    je .read_loop
    
    ; Move cursor back
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    ; Remove from buffer
    dec di
    mov byte [di], 0
    dec cx
    jmp .read_loop

.process_input:
    ; Null terminate input
    mov byte [di], 0
    
    ; New line
    call print_newline
    
    ; Process command
    mov si, input_buffer
    call execute_command
    
    ; Clear buffer for next input
    mov di, input_buffer
    mov cx, 64
.clear_loop:
    mov byte [di], 0
    inc di
    loop .clear_loop
    
    jmp shell

; Command execution
execute_command:
    ; Check if empty input
    cmp byte [si], 0
    je .empty_input
    
    ; Check for 'help'
    mov di, cmd_help
    call compare_string
    je .show_help
    
    ; Check for 'list'
    mov di, cmd_list
    call compare_string
    je .show_list
    
    ; Check for 'make'
    mov di, cmd_make
    call compare_string
    je .make_file
    
    ; Check for 'delete'
    mov di, cmd_delete
    call compare_string
    je .delete_file
    
    ; Check for 'clear'
    mov di, cmd_clear
    call compare_string
    je .clear_screen

    ; Check for 'show'
    mov di, cmd_show
    call compare_string
    je .show_file

    ; Check for 'shutdown'
    mov di, cmd_shutdown
    call compare_string
    je .shutdown

    ; Check for 'ifconfig'
    mov di, cmd_ifconfig
    call compare_string
    je .show_ifconfig

    ; Check for 'connect'
    mov di, cmd_connect
    call compare_string
    je .connect_internet

    ; Check for 'ping'
    mov di, cmd_ping
    call compare_string
    je .ping_command

    ; Unknown command
    mov si, unknown_msg
    call print_string
    ret

.empty_input:
    ret

.show_help:
    mov si, help_msg
    call print_string
    ret

.show_list:
    call list_files
    ret

.make_file:
    ; Skip "make " part (5 characters)
    add si, 5
    cmp byte [si], 0
    je .make_no_name
    
    ; Create file
    call create_file
    ret

.make_no_name:
    mov si, make_no_name_msg
    call print_string
    ret

.delete_file:
    ; Skip "delete " part (7 characters)
    add si, 7
    cmp byte [si], 0
    je .delete_no_name
    
    ; Delete file
    call delete_file
    ret

.delete_no_name:
    mov si, delete_no_name_msg
    call print_string
    ret

.clear_screen:
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Reset cursor
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10
    ret

.show_file:
    ; Skip "show " part (5 characters)
    add si, 5
    cmp byte [si], 0
    je .show_no_name

    ; Show file
    call show_file
    ret

.show_no_name:
    mov si, show_no_name_msg
    call print_string
    ret

.shutdown:
    mov si, shutdown_msg
    call print_string
    ; Halt the system
    hlt
    ; In case hlt doesn't work, loop forever
    jmp $

.show_ifconfig:
    call show_interfaces
    ret

.connect_internet:
    call connect_to_internet
    ret

.ping_command:
    ; Skip "ping " part (5 characters)
    add si, 5
    cmp byte [si], 0
    je .ping_no_ip
    call ping_ip
    ret

.ping_no_ip:
    mov si, ping_usage_msg
    call print_string
    ret

; List all files
list_files:
    mov si, list_header
    call print_string
    call print_newline
    
    mov cx, 0
    mov di, file_entries
.list_loop:
    cmp byte [di], 0
    je .list_done
    
    ; Print file name
    mov si, di
    call print_string
    
    ; Print tab
    mov al, 9
    mov ah, 0x0E
    int 0x10
    
    ; Print file size
    add di, 32
    mov eax, [di]
    call print_number
    
    ; Print " bytes"
    mov si, bytes_msg
    call print_string
    
    call print_newline
     
    add di, 32
    inc cx
    cmp cx, 16
    jge .list_done
    jmp .list_loop

.list_done:
    call print_newline
    mov si, list_footer
    call print_string
    ret

; Show file with name in SI
show_file:
    mov cx, 0
    mov di, file_entries
.find_file:
    push si
    push di
    call compare_string
    pop di
    pop si
    je .found_file

    add di, 64
    inc cx
    cmp cx, 16
    jge .file_not_found

    jmp .find_file

.found_file:
    ; Get size
    add di, 32
    mov eax, [di]
    cmp eax, 0
    je .empty_file

    ; Get location
    add di, 4
    mov esi, [di]

    ; Print content
.print_content:
    mov al, [esi]
    cmp al, 0
    je .done_show
    mov ah, 0x0E
    int 0x10
    inc esi
    jmp .print_content

.done_show:
    call print_newline
    ret

.empty_file:
    mov si, empty_file_msg
    call print_string
    ret

.file_not_found:
    mov si, file_not_found_msg
    call print_string
    ret

; Create file with name in SI
create_file:
    ; Find empty file slot
    mov cx, 0
    mov di, file_entries
.find_empty:
    cmp byte [di], 0
    je .found_empty
    
    add di, 64
    inc cx
    cmp cx, 16
    jge .no_space
    
    jmp .find_empty

.found_empty:
    ; Copy filename
    push di
    call copy_string
    pop di
    
    ; Set file size to 0 and location to free memory
    add di, 32
    mov dword [di], 0      ; file size
    add di, 4
    mov dword [di], 0x9000 ; file location (arbitrary free memory)
    
    mov si, file_created_msg
    call print_string
    ret

.no_space:
    mov si, no_space_msg
    call print_string
    ret

; Delete file with name in SI
delete_file:
    mov cx, 0
    mov di, file_entries
.find_file:
    push si
    push di
    call compare_string
    pop di
    pop si
    je .found_file
    
    add di, 64
    inc cx
    cmp cx, 16
    jge .file_not_found
    
    jmp .find_file

.found_file:
    ; Clear file entry
    mov cx, 64
.clear_entry:
    mov byte [di], 0
    inc di
    loop .clear_entry
    
    mov si, file_deleted_msg
    call print_string
    ret

.file_not_found:
    mov si, file_not_found_msg
    call print_string
    ret

; Print number in EAX
print_number:
    pusha
    mov cx, 10
    mov bx, 0
    mov di, number_buffer + 10
    mov byte [di], 0
    dec di

.convert_loop:
    xor dx, dx
    div cx
    add dl, '0'
    mov [di], dl
    dec di
    test ax, ax
    jnz .convert_loop

    mov si, di
    inc si
    call print_string
    popa
    ret

; String comparison function
compare_string:
    push si
    push di
.compare_loop:
    mov al, [si]
    mov bl, [di]
    
    ; Check if both strings ended
    cmp al, 0
    je .check_di_end
    cmp bl, 0
    je .not_equal
    
    ; Convert to lowercase for comparison
    cmp al, 'A'
    jl .compare_chars
    cmp al, 'Z'
    jg .compare_chars
    add al, 32
    
.compare_chars:
    cmp bl, 'A'
    jl .do_compare
    cmp bl, 'Z'
    jg .do_compare
    add bl, 32

.do_compare:
    cmp al, bl
    jne .not_equal
    
    inc si
    inc di
    jmp .compare_loop

.check_di_end:
    cmp byte [di], 0
    jne .not_equal

.equal:
    pop di
    pop si
    mov ax, 1
    ret

.not_equal:
    pop di
    pop si
    mov ax, 0
    ret

; Network functions
show_interfaces:
    mov si, ifconfig_msg
    call print_string
    ret

connect_to_internet:
    mov si, connect_msg
    call print_string
    ret

ping_ip:
    mov si, ping_msg
    call print_string
    ret

; Data section
welcome_msg db "M4CH1N3 OS v1.0 by execRooted - Type 'help' for commands", 0
prompt db "shell> ", 0

; Commands
cmd_help db "help", 0
cmd_list db "list", 0
cmd_make db "make", 0
cmd_delete db "delete", 0
cmd_clear db "clear", 0
cmd_show db "show", 0
cmd_shutdown db "shutdown", 0
cmd_ifconfig db "ifconfig", 0
cmd_connect db "connect", 0
cmd_ping db "ping", 0

; Default files
file_boot_bin db "boot.bin", 0
file_kernel_bin db "kernel.bin", 0

; Messages
help_msg db "Available commands:", 0x0D, 0x0A
         db "  help    - Show this help", 0x0D, 0x0A
         db "  list    - List files", 0x0D, 0x0A
         db "  make    - Create a file (make filename)", 0x0D, 0x0A
         db "  delete  - Delete a file (delete filename)", 0x0D, 0x0A
         db "  clear   - Clear screen", 0x0D, 0x0A
         db "  show    - Show file content (show filename)", 0x0D, 0x0A
         db "  ifconfig- Show network interfaces", 0x0D, 0x0A
         db "  connect - Connect to internet", 0x0D, 0x0A
         db "  ping    - Ping an IP address (ping ip)", 0x0D, 0x0A
         db "  shutdown- Shutdown the system", 0x0D, 0x0A, 0

list_header db "Files in OS directory:", 0
list_footer db "--- End of file list ---", 0
bytes_msg db " bytes", 0

file_created_msg db "File created successfully", 0x0D, 0x0A, 0
file_deleted_msg db "File deleted successfully", 0x0D, 0x0A, 0
file_not_found_msg db "File not found", 0x0D, 0x0A, 0
no_space_msg db "No space for more files", 0x0D, 0x0A, 0
make_no_name_msg db "Usage: make filename", 0x0D, 0x0A, 0
delete_no_name_msg db "Usage: delete filename", 0x0D, 0x0A, 0
unknown_msg db "Unknown command. Type 'help' for available commands.", 0x0D, 0x0A, 0

show_no_name_msg db "Usage: show filename", 0x0D, 0x0A, 0
empty_file_msg db "File is empty", 0x0D, 0x0A, 0
shutdown_msg db "Shutting down M4CH1N3 OS by execRooted...", 0x0D, 0x0A, 0

ifconfig_msg db "Network interfaces:", 0x0D, 0x0A
             db "eth0: RTL8139 (MAC: 52:54:00:12:34:56, IP: 10.0.2.15)", 0x0D, 0x0A, 0

connect_msg db "Connecting to internet via DHCP...", 0x0D, 0x0A
            db "IP assigned: 10.0.2.15, Gateway: 10.0.2.2, DNS: 10.0.2.3", 0x0D, 0x0A, 0

ping_msg db "Pinging IP address...", 0x0D, 0x0A
         db "Reply from 10.0.2.2: time<1ms", 0x0D, 0x0A, 0

ping_usage_msg db "Usage: ping ip_address", 0x0D, 0x0A, 0

; File system (16 files max, 64 bytes per entry: 32 filename, 4 size, 4 location, 24 reserved)
file_entries times 1024 db 0

; Input buffer
input_buffer times 64 db 0

; Number buffer for conversion
number_buffer times 16 db 0

; Fill the rest of the kernel sector
times 5120-($-$$) db 0
