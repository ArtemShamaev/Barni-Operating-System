; ============= ЗАГРУЗЧИК BarniOS (сектор 1) =============
; Выводит системную информацию, приветствие с именем пользователя,
; запрашивает пароль и при успехе загружает ядро.
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

    ; Очистка экрана с синим фоном
    mov ax, 0x0600
    mov bh, 0x1F
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Вывод информации о системе
    mov si, sysinfo_full
    call print_str

    ; Приветствие с именем пользователя
    mov si, welcome_prefix
    call print_str
    mov si, USERNAME_STR          ; имя из boot_config.inc
    call print_str
    call newline

    ; Запрос пароля
    mov si, password_prompt
    call print_str
    mov di, password_input
    call read_password

    ; Сравнение введённого пароля с сохранённым
    mov si, password_input
    mov di, PASSWORD_STR          ; пароль из boot_config.inc
    call compare_strings
    jc .password_ok

    ; Неверный пароль
    mov si, password_error
    call print_str
    call wait_key
    int 0x19                     ; перезагрузка

.password_ok:
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
   hlt
   jmp $

; ============= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =============

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

newline:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

print_char:
    mov ah, 0x0e
    int 0x10
    ret

; Ожидание нажатия любой клавиши
wait_key:
    xor ax, ax
    int 0x16
    ret

; Чтение пароля: ввод с '*' вместо символов
; DI – буфер для пароля, максимум 32 символа
read_password:
    pusha
    xor cx, cx                  ; счётчик символов
.loop:
    xor ax, ax
    int 0x16
    cmp al, 13                  ; Enter – конец ввода
    je .done
    cmp al, 8                   ; Backspace
    je .backspace
    cmp cx, 31                  ; ограничение длины
    jae .loop
    stosb
    inc cx
    mov al, '*'
    call print_char
    jmp .loop
.backspace:
    test cx, cx
    jz .loop
    dec di
    dec cx
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .loop
.done:
    mov byte [di], 0            ; завершающий ноль
    call newline
    popa
    ret

; Сравнение строк (SI и DI), ZF=1 если равны, CF=1 если равны
compare_strings:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.equal:
    pop di
    pop si
    stc
    ret
.not_equal:
    pop di
    pop si
    clc
    ret

; ============= ДАННЫЕ =============
boot_drive     db 0

sysinfo_full   db '    / \__', 13, 10
               db '   (    @\___', 13, 10
               db '  /        O', 13, 10
               db ' /   (_____/', 13, 10
               db '/_____/   U', 13, 10
               

welcome_prefix db 'hello, ', 0
password_prompt db 'Type password: ', 0
password_error  db 13, 10, 'Wrong password! Press any key.', 0


; Буфер для ввода пароля (32 байта)
password_input  times 32 db 0

; Disk Address Packet для LBA (99 секторов, начиная с LBA=1)
dap:
    db 0x10
    db 0
    dw 99            ; читаем 99 секторов
    dw 0x7e00        ; буфер
    dw 0x0000
    dq 1             ; начальный сектор LBA 1 (второй сектор диска)

; Подключаем конфигурацию (имя пользователя и пароль)
%include "boot_config.inc"

times 510-($-$$) db 0
dw 0xAA55
