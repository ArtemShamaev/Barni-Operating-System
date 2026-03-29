; ============= БАЗОВЫЙ ЗАГРУЗЧИК (сектор 1) =============
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

    ; Очистка экрана с синим фоном
    mov ax, 0x0600
    mov bh, 0x1F
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Вывод информации о системе
    mov si, sysinfo_full
    call print_str_boot

    ; Вывод приглашения
    mov si, press_key_msg
    call print_str_boot

    ; Ожидание нажатия любой клавиши
    xor ax, ax
    int 0x16

    ; Сброс дисковой системы
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    ; Используем только LBA (предполагаем, что оно работает)
    mov si, dap
    mov ah, 0x42
    int 0x13
    jc .disk_error

    ; Если дошли сюда – чтение успешно, переходим на ядро
    jmp 0x0000:0x7e00

.disk_error:
    mov si, disk_error_msg
    call print_str_boot
    ; Ждём нажатия, чтобы увидеть сообщение
    xor ax, ax
    int 0x16
    ; Перезагрузка
    int 0x19

print_str_boot:
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
sysinfo_full   db '     === BarniOS System Information ===', 13, 10
               db '         / \__', 13, 10
               db '        (    @\___', 13, 10
               db '       /        O', 13, 10
               db '      /   (_____/', 13, 10
               db '     /_____/   U', 13, 10
               db '     Copyright (C) BARNINO SYSTEMS & Barni Project Team', 13, 10
               db '     (2026), all rights reserved.', 13, 10
               db '     BarniOS 2.3 with GraFase 2.0 BarnEl 2.4', 13, 10, 0

press_key_msg  db 13, 10, 'Press any key to continue...', 0
disk_error_msg db 13, 10, 'Disk error! Press any key to reboot.', 0

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
