; ============= ЗАГРУЗЧИК BarniOS (сектор 1) =============
; Загружает ядро (99 секторов, начиная с LBA=1)
; При ошибке выводит сообщение и останавливается.
; ========================================================

section .text
use16
org 0x7c00

start:
    ; Сохраняем номер загрузочного диска
    mov [boot_drive], dl

    ; Инициализация сегментов и стека
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Установка текстового режима 80x25
    mov ax, 0x0003
    int 0x10

    ; Сброс дисковой системы
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    ; Загрузка ядра (99 секторов, начиная с LBA=1)
    mov si, dap
    mov ah, 0x42
    int 0x13
    jc .disk_error

    ; Успешная загрузка – переход на ядро
    jmp 0x0000:0x7e00

.disk_error:
    mov si, error_msg
    call print_str
    ; Бесконечный цикл (останов)
    cli
    hlt
    jmp .disk_error

print_str:
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Данные
boot_drive     db 0
error_msg      db 'Barnino Systems found error in your system. Error code: BOOT_PANIC_CANT_LOAD_KERNEL', 13, 10, 0

; Disk Address Packet для LBA (99 секторов, начиная с LBA=1)
dap:
    db 0x10
    db 0
    dw 99            ; читаем 99 секторов
    dw 0x7e00        ; буфер
    dw 0x0000
    dq 1             ; начальный сектор LBA 1 (второй сектор диска)

times 510-($-$$) db 0
dw 0xAA55
