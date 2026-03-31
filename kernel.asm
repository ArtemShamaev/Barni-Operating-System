; ============= ЯДРО BarniOS (сектора 2-100) =============
; Полностью переработанная версия с поддержкой:
; - виртуальной файловой системы в ОЗУ (максимум 16 файлов/директорий)
; - команд cd, mkdir, cd ..
; - обновляемого приглашения с текущим путём
; - текстового редактора с нормальной навигацией
; - игр и калькулятора
; - русского языка и переключения раскладки по Win
; Исправлены все ошибки 16-битной адресации и добавлены недостающие определения команд
; ========================================================

use16
org 0x7e00

; ==================== УСЛОВНАЯ КОМПИЛЯЦИЯ ====================
; Если определён RUSSIAN, используются русские сообщения,
; иначе английские. Имя пользователя и пароль подставляются через sed.
; ==============================================================
init_cyrillic_font:
    pusha
    ; Сохраняем текущий видеорежим
    mov ax, 0x0F00
    int 0x10
    cmp al, 0x03          ; текстовый режим 80x25?
    jne .done

    ; Получаем адрес текущей таблицы шрифтов (int 10h, ax=1130h)
    mov ax, 0x1130
    mov bh, 0x03          ; запросить шрифт 8x16 для символов 0-255
    int 0x10
    ; ES:BP – адрес текущего шрифта (8x16)
    ; Скопируем его в буфер, потом изменим русские символы
    mov cx, 256*16        ; размер шрифта (256 символов * 16 байт)
    mov di, font_buffer
    push ds
    push es
    pop ds
    mov si, bp
    rep movsb
    pop ds

    ; Теперь заменим в буфере шрифт для русских символов
    ; Русские буквы в CP866 расположены в диапазоне 0x80-0xAF
    mov si, cyrillic_font_data
    mov di, font_buffer
    add di, 0x80*16       ; пропускаем первые 128 символов
    mov cx, 48            ; количество русских символов (А-Я, а-я + Ёё)
    ; Копируем данные шрифта (48 символов * 16 байт)
    rep movsb

    ; Загружаем изменённый шрифт в VGA
    mov ax, 0x1110        ; загрузить шрифт
    mov bh, 0x10          ; байт на символ = 16
    mov bl, 0x00          ; блок 0 (символы 0-255)
    mov cx, 256           ; количество символов
    mov dx, 0x0000        ; начиная с символа 0
    push ds
    push cs
    pop ds
    mov bp, font_buffer
    int 0x10
    pop ds

.done:
    popa
    ret
cyrillic_font_data:
    ; А (0x80)
    db 0x00,0x00,0x10,0x38,0x7C,0xFE,0xFE,0xFE,0xFE,0xFE,0x7C,0x38,0x10,0x00,0x00,0x00
    ; Б (0x81)
    db 0x00,0x00,0xFC,0xFE,0xFE,0x0C,0x0C,0xFC,0xFE,0xFE,0xFE,0xFE,0xFC,0x00,0x00,0x00
    ; В (0x82)
    db 0x00,0x00,0xF0,0xFC,0xFC,0x0C,0x0C,0xFC,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00
    ; Г (0x83)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; Д (0x84)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x06,0x06,0x06,0x06,0x0C,0x3C,0x7C,0xFC,0x00,0x00,0x00
    ; Е (0x85)
    db 0x00,0x00,0xFC,0xFE,0xFE,0x30,0x30,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0x00,0x00,0x00
    ; Ж (0x86)
    db 0x00,0x00,0xEE,0xEE,0xFE,0x7C,0x38,0xFE,0xFE,0x7C,0x38,0xEE,0xEE,0x00,0x00,0x00
    ; З (0x87)
    db 0x00,0x00,0xFC,0xFE,0xFE,0x06,0x0C,0x3C,0x3C,0x0C,0x06,0xFE,0xFC,0x00,0x00,0x00
    ; И (0x88)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x18,0x38,0x78,0xF8,0xF8,0x78,0x38,0x18,0x00,0x00,0x00
    ; Й (0x89)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x18,0x38,0x78,0xF8,0xF8,0x78,0x38,0x18,0x18,0x00,0x00
    ; К (0x8A)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x18,0x3C,0x7E,0x7E,0x3C,0x18,0xFE,0xFE,0x00,0x00,0x00
    ; Л (0x8B)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x06,0x06,0x06,0x06,0x06,0x0C,0x1C,0x38,0x00,0x00,0x00
    ; М (0x8C)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x7C,0x38,0x38,0x38,0x38,0x7C,0xFE,0xFE,0x00,0x00,0x00
    ; Н (0x8D)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x30,0xFE,0xFE,0x00,0x00,0x00
    ; О (0x8E)
    db 0x00,0x00,0x7C,0xFE,0xFE,0xC6,0xC6,0xC6,0xC6,0xC6,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; П (0x8F)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; Р (0x90)
    db 0x00,0x00,0xFC,0xFE,0xFE,0x0C,0x0C,0xFC,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00
    ; С (0x91)
    db 0x00,0x00,0x7C,0xFE,0xFE,0xC0,0xC0,0xC0,0xC0,0xC0,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; Т (0x92)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x00,0x00,0x00
    ; У (0x93)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x30,0xFE,0xFE,0x00,0x00,0x00
    ; Ф (0x94)
    db 0x00,0x00,0x7C,0xFE,0xFE,0x6C,0x6C,0x6C,0x6C,0x6C,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; Х (0x95)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x78,0xFC,0xFC,0x78,0x30,0xFE,0xFE,0x00,0x00,0x00
    ; Ц (0x96)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x06,0x06,0x06,0x06,0x06,0xFE,0xFE,0xFE,0x00,0x00,0x00
    ; Ч (0x97)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x60,0x60,0x60,0x60,0x60,0x60,0xFE,0xFE,0x00,0x00,0x00
    ; Ш (0x98)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x06,0x06,0xFE,0xFE,0x06,0x06,0xFE,0xFE,0x00,0x00,0x00
    ; Щ (0x99)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x06,0x06,0xFE,0xFE,0x06,0x06,0xFE,0xFE,0x00,0x00,0x00
    ; Ъ (0x9A)
    db 0x00,0x00,0x30,0x30,0x30,0xFC,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; Ы (0x9B)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0xFC,0xFC,0x30,0x30,0xFE,0xFE,0x00,0x00,0x00
    ; Ь (0x9C)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; Э (0x9D)
    db 0x00,0x00,0x7C,0xFE,0xFE,0xC0,0xC0,0xF8,0xF8,0xC0,0xC0,0xFE,0x7C,0x00,0x00,0x00
    ; Ю (0x9E)
    db 0x00,0x00,0xFE,0xFE,0xFE,0x18,0x3C,0x7E,0x7E,0x3C,0x18,0xFE,0xFE,0x00,0x00,0x00
    ; Я (0x9F)
    db 0x00,0x00,0xFC,0xFE,0xFE,0x06,0x06,0xFC,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00
    ; а (0xA0)
    db 0x00,0x00,0x00,0x00,0x78,0xFC,0xFC,0x0C,0x7C,0xFC,0xFC,0xFC,0x7C,0x00,0x00,0x00
    ; б (0xA1)
    db 0x00,0x00,0x1C,0x3C,0x7C,0x7C,0x7C,0x1C,0x0C,0xFC,0xFC,0xFC,0x78,0x00,0x00,0x00
    ; в (0xA2)
    db 0x00,0x00,0x00,0x00,0xF0,0xFC,0xFC,0x0C,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00
    ; г (0xA3)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; д (0xA4)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x06,0x06,0x0C,0x3C,0x7C,0xFC,0x00,0x00,0x00
    ; е (0xA5)
    db 0x00,0x00,0x00,0x00,0x78,0xFC,0xFC,0xC0,0xFC,0xFC,0xFC,0xFC,0x78,0x00,0x00,0x00
    ; ж (0xA6)
    db 0x00,0x00,0x00,0x00,0xEE,0xEE,0x7C,0x38,0x7C,0xEE,0xEE,0xEE,0xEE,0x00,0x00,0x00
    ; з (0xA7)
    db 0x00,0x00,0x00,0x00,0x7C,0xFE,0xFE,0x0C,0x3C,0x0C,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; и (0xA8)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x18,0x38,0x78,0xF8,0xF8,0x78,0x00,0x00,0x00
    ; й (0xA9)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x18,0x38,0x78,0xF8,0xF8,0x78,0x18,0x00,0x00
    ; к (0xAA)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x78,0xFC,0x78,0x30,0xFC,0x00,0x00,0x00
    ; л (0xAB)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x06,0x06,0x06,0x0C,0x1C,0x38,0x00,0x00,0x00
    ; м (0xAC)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x7C,0x38,0x38,0x7C,0xFC,0xFC,0x00,0x00,0x00
    ; н (0xAD)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0xFC,0xFC,0x00,0x00,0x00
    ; о (0xAE)
    db 0x00,0x00,0x00,0x00,0x7C,0xFE,0xFE,0xC6,0xC6,0xC6,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; п (0xAF)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; р (0xB0)
    db 0x00,0x00,0x00,0x00,0xF0,0xFC,0xFC,0x0C,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00
    ; с (0xB1)
    db 0x00,0x00,0x00,0x00,0x7C,0xFE,0xFE,0xC0,0xC0,0xC0,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; т (0xB2)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; у (0xB3)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0xFC,0xFC,0x00,0x00,0x00
    ; ф (0xB4)
    db 0x00,0x00,0x00,0x00,0x7C,0xFE,0xFE,0x6C,0x6C,0x6C,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; х (0xB5)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x78,0xFC,0x78,0x30,0xFC,0x00,0x00,0x00
    ; ц (0xB6)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x06,0x06,0x06,0xFC,0xFC,0xFC,0x00,0x00,0x00
    ; ч (0xB7)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x60,0x60,0x60,0x60,0xFC,0xFC,0x00,0x00,0x00
    ; ш (0xB8)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x06,0x06,0xFC,0xFC,0x06,0x06,0x00,0x00,0x00
    ; щ (0xB9)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x06,0x06,0xFC,0xFC,0x06,0x06,0x00,0x00,0x00
    ; ъ (0xBA)
    db 0x00,0x00,0x00,0x00,0x30,0x30,0x30,0xFC,0xFC,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; ы (0xBB)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0xFC,0xFC,0x30,0x30,0x00,0x00,0x00
    ; ь (0xBC)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x30,0x30,0x30,0x30,0x30,0x30,0x00,0x00,0x00
    ; э (0xBD)
    db 0x00,0x00,0x00,0x00,0x7C,0xFE,0xFE,0xC0,0xF8,0xC0,0xFE,0xFE,0x7C,0x00,0x00,0x00
    ; ю (0xBE)
    db 0x00,0x00,0x00,0x00,0xFC,0xFC,0xFC,0x18,0x3C,0x7E,0x3C,0x18,0xFC,0x00,0x00,0x00
    ; я (0xBF)
    db 0x00,0x00,0x00,0x00,0xF0,0xFC,0xFC,0x0C,0xFC,0xFC,0xFC,0xFC,0xF0,0x00,0x00,0x00

font_buffer times 256*16 db 0
kernel_start:
    ; Инициализация сегментов и стека
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    mov al, 0
    call init_cyrillic_font
    ; Инициализация файловой системы (создаём docs.txt)
    call init_filesystem

    ; Устанавливаем текущую директорию в корень
    mov si, root_path
    mov di, current_path
    call strcpy

    ; Инициализация графического интерфейса
    call init_interface

    ; === ЗАПРОС ПАРОЛЯ ===
    call password_login

    ; Основной цикл
main_loop:
    call update_time_display
    call draw_prompt
    call get_command
    call process_command
    jmp main_loop

; ============= КОНСТАНТЫ ФАЙЛОВОЙ СИСТЕМЫ =============
MAX_FILES        equ 16                 ; максимальное число файлов
FILENAME_SIZE    equ 32                 ; длина имени (с учётом 0)
FILE_DATA_SIZE   equ 1024               ; размер данных файла
FILE_STRUCT_SIZE equ FILENAME_SIZE + 2 + FILE_DATA_SIZE

; Смещения полей в структуре файла
FILE_NAME_OFFSET equ 0
FILE_SIZE_OFFSET equ FILENAME_SIZE
FILE_DATA_OFFSET equ FILENAME_SIZE + 2

; Массив файлов (располагается сразу за кодом)
files:
    times MAX_FILES * FILE_STRUCT_SIZE db 0

; Буферы и переменные
filename_buffer   times FILENAME_SIZE db 0   ; временное имя файла
current_path      times 64 db 0               ; текущий путь (например "C:\")
root_path         db 'C:\', 0

; ============= ИНИЦИАЛИЗАЦИЯ ФС =============
init_filesystem:
    pusha
    ; Создаём файл документации "docs.txt"
    mov di, files
    mov si, docs_name_str
    mov cx, FILENAME_SIZE
    call strncpy_zero
    mov word [di + FILE_SIZE_OFFSET], docs_len
    lea di, [di + FILE_DATA_OFFSET]
    mov si, docs_content
    mov cx, docs_len
    rep movsb
    popa
    ret

docs_name_str db 'docs.txt', 0

docs_content:
    db '====================================', 13,10
    db '        BarniOS Documentation', 13,10
    db '====================================', 13,10
    db 'Commands:', 13,10
    db '  ls               - list files', 13,10
    db '  write to <file>  - create new file', 13,10
    db '  write in <file>  - open existing file', 13,10
    db '  cd <dir>         - change directory', 13,10
    db '  cd ..            - go up', 13,10
    db '  mkdir <dir>      - create directory', 13,10
    db '  clr              - clear screen', 13,10
    db '  reboot           - restart', 13,10
    db '  help             - show help', 13,10
    db '  sysinfo          - system info', 13,10
    db '  guess            - number game', 13,10
    db '  calc             - calculator', 13,10
    db '  time             - show time', 13,10
    db '  date             - show date', 13,10
    db '',13,10
    db 'Directories are files whose name ends with "/".', 13,10
    db '====================================', 13,10,0
docs_len equ $ - docs_content

; ============= СТРОКОВЫЕ ФУНКЦИИ =============
; Копирование строки с заполнением нулями до длины CX
; SI -> DI, CX = размер буфера
strncpy_zero:
    push ax
.loop:
    lodsb
    stosb
    test al, al
    jz .fill
    loop .loop
    jmp .done
.fill:
    dec di
    inc cx
    xor al, al
    rep stosb
.done:
    pop ax
    ret

; Копирование строки до нуля (SI -> DI)
strcpy:
    push ax
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop ax
    ret

; Сравнение строк SI и DI, возврат CF=1 если равны
strcmp:
    push ax
    push si
    push di
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    clc
    pop di
    pop si
    pop ax
    ret
.equal:
    stc
    pop di
    pop si
    pop ax
    ret

; Получить длину строки (SI) -> AX
strlen:
    push si
    xor ax, ax
.loop:
    cmp byte [si], 0
    je .done
    inc si
    inc ax
    jmp .loop
.done:
    pop si
    ret

; ============= ПОИСК ФАЙЛОВ =============
; Найти файл по имени (SI) -> DI = указатель, CF=1 если найден
find_file_by_name:
    push si
    push cx
    push ax
    mov di, files
    mov cx, MAX_FILES
.loop:
    push di
    push si
    call strcmp
    pop si
    pop di
    jc .found
    add di, FILE_STRUCT_SIZE
    loop .loop
    pop ax
    pop cx
    pop si
    clc
    ret
.found:
    pop ax
    pop cx
    pop si
    stc
    ret

; Найти свободный слот (размер = 0) -> DI, CF=1 если есть
find_free_slot:
    push cx
    push ax
    mov di, files
    mov cx, MAX_FILES
.loop:
    cmp word [di + FILE_SIZE_OFFSET], 0
    je .found
    add di, FILE_STRUCT_SIZE
    loop .loop
    pop ax
    pop cx
    clc
    ret
.found:
    pop ax
    pop cx
    stc
    ret

; ============= ИЗВЛЕЧЕНИЕ ИМЕНИ ФАЙЛА =============
; Из строки SI (команда) копирует имя до пробела или конца в filename_buffer
; Возвращает CF=1 если имя не пустое
extract_filename:
    push di
    push si
    push ax
    mov di, filename_buffer
    xor cx, cx
.loop:
    lodsb
    cmp al, ' '
    je .done
    test al, al
    jz .done
    stosb
    inc cx
    cmp cx, FILENAME_SIZE-1
    jae .done
    jmp .loop
.done:
    mov byte [di], 0
    test cx, cx
    jz .empty
    stc
    jmp .ret
.empty:
    clc
.ret:
    pop ax
    pop si
    pop di
    ret

; ============= ОПЕРАЦИИ С ФАЙЛАМИ =============
create_file:
    pusha
    call find_free_slot
    jc .have_slot
    mov si, err_no_free
    call print_str
    popa
    ret
.have_slot:
    push di
    mov si, filename_buffer
    mov cx, FILENAME_SIZE
    call strncpy_zero
    pop di
    mov word [di + FILE_SIZE_OFFSET], 0
    call edit_file
    popa
    ret

open_file:
    pusha
    mov si, filename_buffer
    call find_file_by_name
    jc .found
    mov si, err_not_found
    call print_str
    popa
    ret
.found:
    call edit_file
    popa
    ret

; ============= КОМАНДЫ ДЛЯ ДИРЕКТОРИЙ =============
; cd <dirname>
cd_command:
    pusha
    mov si, command_buffer + 3          ; после "cd "
    call extract_filename
    jnc .error
    ; Добавляем '/' к имени
    mov di, filename_buffer
    call strlen
    mov bx, ax
    cmp bx, FILENAME_SIZE-2
    jae .error
    mov byte [filename_buffer + bx], '/'
    mov byte [filename_buffer + bx + 1], 0
    ; Ищем такой файл
    mov si, filename_buffer
    call find_file_by_name
    jnc .not_found
    ; Проверяем, что это директория (имя оканчивается на '/')
    ; (мы только что добавили '/', так что подходит)
    ; Добавляем к текущему пути
    call append_to_path
    jmp .done
.not_found:
    mov si, err_not_found
    call print_str
    jmp .done
.error:
    mov si, err_invalid_name
    call print_str
.done:
    popa
    ret

; cd ..
cd_up_command:
    pusha
    mov si, current_path
    call remove_last_component
    jc .done
    mov si, err_cd_up
    call print_str
.done:
    popa
    ret

; mkdir <dirname>
mkdir_command:
    pusha
    mov si, command_buffer + 6          ; после "mkdir "
    call extract_filename
    jnc .error
    ; Добавляем '/' в конец
    mov di, filename_buffer
    call strlen
    mov bx, ax
    cmp bx, FILENAME_SIZE-2
    jae .error
    mov byte [filename_buffer + bx], '/'
    mov byte [filename_buffer + bx + 1], 0
    ; Создаём файл с размером 0
    call find_free_slot
    jc .have_slot
    mov si, err_no_free
    call print_str
    popa
    ret
.have_slot:
    push di
    mov si, filename_buffer
    mov cx, FILENAME_SIZE
    call strncpy_zero
    pop di
    mov word [di + FILE_SIZE_OFFSET], 0
    popa
    ret
.error:
    mov si, err_invalid_name
    call print_str
    popa
    ret

; Добавить компонент пути из filename_buffer в current_path
append_to_path:
    pusha
    mov si, current_path
    call strlen
    mov bx, ax
    ; Проверяем, нужен ли обратный слеш
    cmp bx, 0
    je .no_slash
    dec bx
    cmp byte [current_path + bx], '\'
    je .has_slash
    inc bx
.no_slash:
    mov byte [current_path + bx], '\'
    inc bx
.has_slash:
    ; Копируем имя, заменяя '/' на '\'
    mov si, filename_buffer
    lea di, [current_path + bx]
.copy:
    lodsb
    cmp al, '/'
    je .replace
    test al, al
    jz .done
    stosb
    jmp .copy
.replace:
    mov al, '\'
    stosb
    jmp .copy
.done:
    popa
    ret

; Удалить последний компонент пути (после последнего '\')
remove_last_component:
    push si
    push ax
    mov si, current_path
    call strlen
    test ax, ax
    jz .root
    mov bx, ax
    dec bx
.find:
    cmp bx, 0
    jl .root
    cmp byte [current_path + bx], '\'
    je .found
    dec bx
    jmp .find
.found:
    cmp bx, 0
    je .root_slash
    mov byte [current_path + bx + 1], 0
    stc
    jmp .done
.root_slash:
    mov word [current_path], 'C'
    mov word [current_path+1], ':\'
    mov byte [current_path+3], 0
    stc
    jmp .done
.root:
    clc
.done:
    pop ax
    pop si
    ret

; ============= ВЫВОД СПИСКА ФАЙЛОВ =============
list_files:
    pusha
    mov si, files
    mov cx, MAX_FILES
.loop:
    cmp word [si + FILE_SIZE_OFFSET], 0
    je .next
    push si
    lea si, [si + FILE_NAME_OFFSET]
    call print_file_entry
    pop si
.next:
    add si, FILE_STRUCT_SIZE
    loop .loop
    popa
    ret

print_file_entry:
    push si
    push ax
    push bx
    push di                ; используем di как индексный регистр
    mov bx, si             ; сохраняем начало имени
    ; Проверяем, директория ли это (последний символ '/')
    push si
    call strlen
    pop si
    cmp ax, 0
    je .regular
    dec ax
    mov di, ax             ; сохраняем индекс в di (допустимый индексный регистр)
    cmp byte [bx + di], '/'
    je .directory
.regular:
    ; Обычный файл
    mov si, bx
    call print_str
    jmp .print_size
.directory:
    ; Директория: выводим [DIR] и имя без слеша
    push si
    mov si, dir_prefix
    call print_str
    pop si
    mov si, bx
    call print_str_until_slash
.print_size:
    mov al, ' '
    call print_char
    mov al, '('
    call print_char
    ; Получаем размер (bx указывает на имя, структура начинается на bx - FILE_NAME_OFFSET)
    lea si, [bx - FILE_NAME_OFFSET]
    mov ax, [si + FILE_SIZE_OFFSET]
    call print_number
    mov al, ' '
    call print_char
    mov al, 'b'
    call print_char
    mov al, ')'
    call print_char
    call new_line
    pop di
    pop bx
    pop ax
    pop si
    ret

dir_prefix db '[DIR] ', 0

print_str_until_slash:
    push ax
.loop:
    lodsb
    cmp al, '/'
    je .done
    test al, al
    jz .done
    call print_char
    jmp .loop
.done:
    pop ax
    ret

; ============= ТЕКСТОВЫЙ РЕДАКТОР =============
edit_file:
    pusha
    mov [edit_file_ptr], di

    ; Проверка на read-only (docs.txt)
    push di
    lea di, [di + FILE_NAME_OFFSET]
    mov si, docs_name_str
    call strcmp
    pop di
    mov byte [read_only_flag], 0
    jnc .not_docs
    mov byte [read_only_flag], 1
    mov si, err_readonly
    call print_str
.not_docs:

    lea bx, [di + FILE_DATA_OFFSET]
    mov [edit_data_ptr], bx
    mov cx, [di + FILE_SIZE_OFFSET]
    mov [edit_file_size], cx
    mov word [cursor_pos], 0
    mov word [screen_top], 0
    call update_cursor_row_col
    call editor_draw_interface

.editor_loop:
    call editor_refresh_text
    call update_status_line
    call editor_set_cursor
    call getchar_layout   ; вместо int 0x16
    ; Проверка на специальные клавиши (скан-код в AH)
    cmp ah, 0x01          ; ESC
    je .exit_editor
    cmp ah, 0x48          ; Up
    je .cursor_up
    cmp ah, 0x50          ; Down
    je .cursor_down
    cmp ah, 0x4B          ; Left
    je .cursor_left
    cmp ah, 0x4D          ; Right
    je .cursor_right
    cmp ah, 0x0E          ; Backspace
    je .backspace
    cmp ah, 0x1C          ; Enter
    je .enter_pressed
    cmp ah, 0x49          ; Page Up
    je .page_up
    cmp ah, 0x51          ; Page Down
    je .page_down

    cmp al, 0x20
    jb .editor_loop
    cmp al, 0x7F
    jae .editor_loop
    cmp byte [read_only_flag], 1
    je .editor_loop
    call editor_insert_char
    jmp .editor_loop

.cursor_up:
    call editor_cursor_up
    jmp .editor_loop
.cursor_down:
    call editor_cursor_down
    jmp .editor_loop
.cursor_left:
    call editor_cursor_left
    jmp .editor_loop
.cursor_right:
    call editor_cursor_right
    jmp .editor_loop
.backspace:
    cmp byte [read_only_flag], 1
    je .editor_loop
    call editor_backspace
    jmp .editor_loop
.enter_pressed:
    cmp byte [read_only_flag], 1
    je .editor_loop
    mov al, 13
    call editor_insert_char
    jmp .editor_loop
.page_up:
    mov ax, [screen_top]
    sub ax, screen_rows
    jns .pu_ok
    xor ax, ax
.pu_ok:
    mov [screen_top], ax
    jmp .editor_loop
.page_down:
    mov ax, [screen_top]
    add ax, screen_rows
    cmp ax, [edit_file_size]
    jb .pd_ok
    jmp .editor_loop
.pd_ok:
    mov [screen_top], ax
    jmp .editor_loop

.exit_editor:
    mov di, [edit_file_ptr]
    mov ax, [edit_file_size]
    mov [di + FILE_SIZE_OFFSET], ax
    call init_interface
    popa
    ret

; Переменные редактора
edit_file_ptr    dw 0
edit_data_ptr    dw 0
edit_file_size   dw 0
cursor_pos       dw 0
screen_top       dw 0
read_only_flag   db 0
cursor_row       dw 0
cursor_col       dw 0
screen_rows      equ 22
screen_cols      equ 78

; Обновление позиции курсора и screen_top
update_cursor_row_col:
    pusha
    mov si, [edit_data_ptr]
    mov cx, [cursor_pos]
    mov word [cursor_row], 0
    mov word [cursor_col], 0
    mov dx, 0          ; строка
    mov bx, 0          ; колонка
    jcxz .done
.pos_loop:
    lodsb
    cmp al, 13
    je .newline
    inc bx
    jmp .next
.newline:
    inc dx
    xor bx, bx
.next:
    loop .pos_loop
.done:
    mov [cursor_row], dx
    mov [cursor_col], bx
    ; Корректировка screen_top
    mov ax, [screen_top]
    cmp dx, ax
    jae .check_bottom
    mov [screen_top], dx
    jmp .finish
.check_bottom:
    add ax, screen_rows
    dec ax
    cmp dx, ax
    jbe .finish
    mov ax, dx
    sub ax, screen_rows
    inc ax
    mov [screen_top], ax
.finish:
    popa
    ret

; Отрисовка интерфейса редактора
editor_draw_interface:
    mov ax, 0x0003
    int 0x10
    ; Верхняя рамка
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov al, 0xC9
    call print_char
    mov al, 0xCD
    mov cx, 78
.top_line:
    call print_char
    loop .top_line
    mov al, 0xBB
    call print_char
    ; Боковые рамки
    mov cx, 23
    mov dh, 1
.sides:
    mov dl, 0
    call set_cursor
    mov al, 0xBA
    call print_char
    mov dl, 79
    call set_cursor
    mov al, 0xBA
    call print_char
    inc dh
    loop .sides
    ; Нижняя рамка
    mov dh, 24
    mov dl, 0
    call set_cursor
    mov al, 0xC8
    call print_char
    mov al, 0xCD
    mov cx, 78
.bottom_line:
    call print_char
    loop .bottom_line
    mov al, 0xBC
    call print_char
    ; Заголовок (синий)
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F
    mov cx, 0x0001
    mov dx, 0x004E
    int 0x10
    mov dh, 0
    mov dl, 2
    call set_cursor
    mov si, [edit_file_ptr]
    add si, FILE_NAME_OFFSET
    call print_str
    ; Кнопки
    mov dl, 72
    call set_cursor
    mov al, 0x5F
    call print_char
    mov dl, 74
    call set_cursor
    mov al, 0xB0
    call print_char
    mov dl, 76
    call set_cursor
    mov al, 'X'
    call print_char
    ; Строка состояния (синий)
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F
    mov cx, 0x1701
    mov dx, 0x174E
    int 0x10
    ; Рабочая область (белый)
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0101
    mov dx, 0x164E
    int 0x10
    ret

update_status_line:
    pusha
    mov dh, 23
    mov dl, 1
    call set_cursor
    ; Очистка строки
    mov cx, 78
    mov al, ' '
.clear:
    call print_char
    loop .clear
    mov dh, 23
    mov dl, 1
    call set_cursor
    ; Имя файла
    mov si, [edit_file_ptr]
    add si, FILE_NAME_OFFSET
    call print_str
    ; Позиция
    mov dl, 30
    call set_cursor
    mov si, status_line_pos
    call print_str
    mov ax, [cursor_row]
    inc ax
    call print_number
    mov al, ':'
    call print_char
    mov ax, [cursor_col]
    inc ax
    call print_number
    ; Размер
    mov dl, 45
    call set_cursor
    mov si, status_line_size
    call print_str
    mov ax, [edit_file_size]
    call print_number
    mov al, ' '
    call print_char
    mov al, 'b'
    call print_char
    ; Read-only
    cmp byte [read_only_flag], 1
    jne .not_readonly
    mov dl, 60
    call set_cursor
    mov si, status_line_ro
    call print_str
.not_readonly:
    popa
    ret

status_line_pos  db 'Ln ', 0
status_line_size db 'Size: ', 0
status_line_ro   db '[READ ONLY]', 0

editor_refresh_text:
    pusha
    mov si, [edit_data_ptr]
    mov cx, [edit_file_size]
    mov dx, [screen_top]
.skip_loop:
    test dx, dx
    jz .display
    dec dx
    inc si
    loop .skip_loop
    jmp .done
.display:
    mov dh, 1
    mov dl, 1
.line_loop:
    cmp dh, 23
    jae .done
    call set_cursor
.next_char:
    cmp cx, 0
    je .done
    lodsb
    dec cx
    cmp al, 13
    je .newline
    call print_char
    inc dl
    cmp dl, 79
    jb .next_char
.newline:
    inc dh
    mov dl, 1
    jmp .line_loop
.done:
    popa
    ret

editor_set_cursor:
    pusha
    mov ax, [cursor_row]
    sub ax, [screen_top]
    cmp ax, 0
    jl .at_top
    cmp ax, screen_rows
    jge .at_bottom
    add ax, 1
    mov dh, al
    mov dl, [cursor_col]
    inc dl
    call set_cursor
    popa
    ret
.at_top:
    mov dh, 1
    mov dl, 1
    call set_cursor
    popa
    ret
.at_bottom:
    mov dh, 22
    mov dl, 1
    call set_cursor
    popa
    ret

editor_cursor_up:
    pusha
    mov si, [edit_data_ptr]
    mov bx, [cursor_pos]
    test bx, bx
    jz .done
    dec bx
.search_prev:
    mov al, [si + bx]
    cmp al, 13
    je .found_prev
    test bx, bx
    jz .to_start
    dec bx
    jmp .search_prev
.to_start:
    mov word [cursor_pos], 0
    jmp .done
.found_prev:
    inc bx
    mov [cursor_pos], bx
.done:
    call update_cursor_row_col
    popa
    ret

editor_cursor_down:
    pusha
    mov si, [edit_data_ptr]
    mov bx, [cursor_pos]
    mov dx, [edit_file_size]
.search_next:
    cmp bx, dx
    jae .done
    mov al, [si + bx]
    cmp al, 13
    je .found_next
    inc bx
    jmp .search_next
.found_next:
    inc bx
    cmp bx, dx
    jae .done
    mov [cursor_pos], bx
.done:
    call update_cursor_row_col
    popa
    ret

editor_cursor_left:
    pusha
    mov ax, [cursor_pos]
    test ax, ax
    jz .done
    dec ax
    mov [cursor_pos], ax
    call update_cursor_row_col
.done:
    popa
    ret

editor_cursor_right:
    pusha
    mov ax, [cursor_pos]
    cmp ax, [edit_file_size]
    jae .done
    inc ax
    mov [cursor_pos], ax
    call update_cursor_row_col
.done:
    popa
    ret

editor_insert_char:
    pusha
    mov bx, [edit_data_ptr]
    mov cx, [edit_file_size]
    mov dx, [cursor_pos]
    cmp cx, FILE_DATA_SIZE - 2
    jae .done
    push ds
    push es
    push si
    push di
    mov si, bx
    add si, cx
    mov di, si
    inc di
    std
    mov cx, [edit_file_size]
    sub cx, dx
    rep movsb
    cld
    mov di, bx
    add di, dx
    mov [di], al
    inc word [edit_file_size]
    inc word [cursor_pos]
.done:
    call update_cursor_row_col
    pop di
    pop si
    pop es
    pop ds
    popa
    ret

editor_backspace:
    pusha
    mov bx, [edit_data_ptr]
    mov cx, [cursor_pos]
    test cx, cx
    jz .done
    dec cx
    push ds
    push es
    push si
    push di
    mov si, bx
    add si, cx
    inc si
    mov di, bx
    add di, cx
    mov cx, [edit_file_size]
    sub cx, [cursor_pos]
    rep movsb
    dec word [edit_file_size]
    dec word [cursor_pos]
.done:
    call update_cursor_row_col
    pop di
    pop si
    pop es
    pop ds
    popa
    ret

; ============= ИНТЕРФЕЙС =============
init_interface:
    mov ax, 0x0003
    int 0x10
    call draw_window_frame
    call draw_title_bar
    call draw_menu_bar
    call draw_status_bar
    call draw_workspace
    ret

draw_window_frame:
    mov dh, 0
    mov dl, 0
    call set_cursor
    mov al, 0xC9
    call print_char
    mov al, 0xCD
    mov cx, 78
.top_line:
    call print_char
    loop .top_line
    mov al, 0xBB
    call print_char
    mov cx, 23
    mov dh, 1
.sides:
    mov dl, 0
    call set_cursor
    mov al, 0xBA
    call print_char
    mov dl, 79
    call set_cursor
    mov al, 0xBA
    call print_char
    inc dh
    loop .sides
    mov dh, 24
    mov dl, 0
    call set_cursor
    mov al, 0xC8
    call print_char
    mov al, 0xCD
    mov cx, 78
.bottom_line:
    call print_char
    loop .bottom_line
    mov al, 0xBC
    call print_char
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0101
    mov dx, 0x174E
    int 0x10
    ret

draw_title_bar:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F
    mov cx, 0x0001
    mov dx, 0x004E
    int 0x10
    mov dh, 0
    mov dl, 2
    call set_cursor
    mov si, title_text
    call print_str
    mov dl, 72
    call set_cursor
    mov al, 0x5F
    call print_char
    mov dl, 74
    call set_cursor
    mov al, 0xB0
    call print_char
    mov dl, 76
    call set_cursor
    mov al, 'X'
    call print_char
    ret

draw_menu_bar:
    mov dh, 1
    mov dl, 1
    call set_cursor
    mov ah, 0x06
    mov al, 0
    mov bh, 0x10
    mov cx, 0x0101
    mov dx, 0x014E
    int 0x10
    mov si, menu_file
    call print_str
    mov si, menu_edit
    call print_str
    mov si, menu_view
    call print_str
    mov si, menu_help
    call print_str
    ret

draw_status_bar:
    mov dh, 23
    mov dl, 1
    call set_cursor
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F
    mov cx, 0x1701
    mov dx, 0x174E
    int 0x10
    mov si, status_text
    call print_str
    mov dl, 60
    call set_cursor
    mov si, caps_status
    call print_str
    ret

draw_workspace:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0201
    mov dx, 0x164E
    int 0x10
    mov dh, 3
    mov dl, 10
    call set_cursor
    mov si, welcome_msg
    call print_str
    mov si, username_str
    call print_str
    mov al, '!'
    call print_char
    mov dh, 5
    mov dl, 10
    call set_cursor
    mov si, system_info
    call print_str
    mov dh, 8
    mov dl, 10
    call set_cursor
    mov si, commands_list
    call print_str
    mov dh, 12
    mov dl, 10
    call set_cursor
    ret

draw_prompt:
    mov dh, 22
    mov dl, 1
    call set_cursor
    mov ah, 0x06
    mov al, 0
    mov bh, 0x17
    mov cx, 0x1601
    mov dx, 0x164E
    int 0x10
    mov dh, 22
    mov dl, 3
    call set_cursor
    mov si, current_path
    call print_str
    mov al, '>'
    call print_char
    mov al, ' '
    call print_char
    ret

; ============= БАЗОВЫЙ ВВОД/ВЫВОД =============
set_cursor:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

print_char:
    mov ah, 0x0e
    int 0x10
    ret

print_str:
    push si
.loop:
    lodsb
    test al, al
    jz .done
    call print_char
    jmp .loop
.done:
    pop si
    ret

new_line:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

; ============= ВВОД КОМАНДЫ =============
get_command:
    mov di, command_buffer
    mov byte [cmd_length], 0
    ; Очистка поля ввода
    mov cx, 50
    mov al, ' '
.clear:
    call print_char
    loop .clear
    mov dh, 22
    mov dl, 17
    call set_cursor
.input_loop:
    call getchar_layout
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    cmp al, 27
    je .escape
    cmp byte [cmd_length], 49
    jae .input_loop
    cmp al, ' '
    jb .input_loop
    cmp al, '~'
    ja .input_loop
    stosb
    inc byte [cmd_length]
    call print_char
    jmp .input_loop
.backspace:
    cmp byte [cmd_length], 0
    je .input_loop
    dec di
    dec byte [cmd_length]
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .input_loop
.enter:
    mov byte [di], 0
    call new_line
    ret
.escape:
    mov byte [command_buffer], 0
    mov byte [cmd_length], 0
    jmp get_command

; ============= СРАВНЕНИЕ КОМАНД =============
compare_strings:
    pusha
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
    popa
    stc
    ret
.not_equal:
    popa
    clc
    ret

compare_strings_prefix:
    push si
    push di
.loop:
    mov al, [di]
    test al, al
    jz .match
    cmp al, [si]
    jne .no_match
    inc si
    inc di
    jmp .loop
.match:
    pop di
    pop si
    stc
    ret
.no_match:
    pop di
    pop si
    clc
    ret

; ============= ВРЕМЯ И ДАТА =============
get_time_string:
    mov ah, 0x02
    int 0x1A
    mov al, ch
    call bcd_to_ascii
    mov byte [time_str], al
    mov byte [time_str+1], ah
    mov byte [time_str+2], ':'
    mov al, cl
    call bcd_to_ascii
    mov byte [time_str+3], al
    mov byte [time_str+4], ah
    mov byte [time_str+5], 0
    ret

get_date_string:
    mov ah, 0x04
    int 0x1A
    mov al, dl
    call bcd_to_ascii
    mov byte [date_str], al
    mov byte [date_str+1], ah
    mov byte [date_str+2], '.'
    mov al, dh
    call bcd_to_ascii
    mov byte [date_str+3], al
    mov byte [date_str+4], ah
    mov byte [date_str+5], '.'
    mov al, ch
    call bcd_to_ascii
    mov byte [date_str+6], al
    mov byte [date_str+7], ah
    mov al, cl
    call bcd_to_ascii
    mov byte [date_str+8], al
    mov byte [date_str+9], ah
    mov byte [date_str+10], 0
    ret

bcd_to_ascii:
    push cx
    mov ah, al
    shr al, 4
    and al, 0x0F
    add al, '0'
    and ah, 0x0F
    add ah, '0'
    pop cx
    ret

update_time_display:
    pusha
    call get_time_string
    mov dh, 1
    mov dl, 70
    call set_cursor
    mov al, ' '
    call print_char
    mov si, time_str
    call print_str
    popa
    ret

; ============= ИГРА "УГАДАЙ ЧИСЛО" =============
guess_game:
    mov ax, 0x0003
    int 0x10
    mov ah, 0x06
    mov al, 0
    mov bh, 0x0A
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    xor ah, ah
    int 0x1A
    mov ax, dx
    xor dx, dx
    mov cx, 101
    div cx
    mov [secret_num], dl
    mov word [attempt_count], 0
    mov dh, 2
    mov dl, 20
    call set_cursor
    mov si, game_title
    call print_str
    mov dh, 4
    mov dl, 10
    call set_cursor
    mov si, game_welcome
    call print_str
    mov dh, 6
    mov dl, 10
    call set_cursor
    mov si, game_instructions
    call print_str
.game_main_loop:
    mov dh, 8
    mov dl, 10
    call set_cursor
    mov si, game_attempt
    call print_str
    mov ax, [attempt_count]
    call print_number
    mov dh, 10
    mov dl, 10
    call set_cursor
    mov si, game_prompt
    call print_str
    call get_user_number
    cmp byte [input_valid_flag], 0
    je .invalid_input
    inc word [attempt_count]
    mov al, [user_input]
    cmp al, [secret_num]
    jl .too_low
    jg .too_high
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, game_correct
    call print_str
    mov ax, [attempt_count]
    call print_number
    mov si, game_congrats
    call print_str
    mov dh, 16
    mov dl, 10
    call set_cursor
    mov si, game_exit_msg
    call print_str
    call wait_any_key
    ret
.too_low:
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, game_too_low
    call print_str
    jmp .continue_game
.too_high:
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, game_too_high
    call print_str
    jmp .continue_game
.invalid_input:
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, game_invalid
    call print_str
.continue_game:
    mov dh, 10
    mov dl, 22
    call set_cursor
    mov cx, 10
.clear_prompt:
    mov al, ' '
    call print_char
    loop .clear_prompt
    jmp .game_main_loop

get_user_number:
    mov byte [input_valid_flag], 0
    mov di, num_buffer
    mov byte [num_buffer_len], 0
    mov dh, 10
    mov dl, 22
    call set_cursor
.input_num:
    call getchar_layout
    cmp al, 13
    je .process
    cmp al, 8
    je .backspace
    cmp al, '0'
    jb .input_num
    cmp al, '9'
    ja .input_num
    cmp byte [num_buffer_len], 3
    jae .input_num
    stosb
    inc byte [num_buffer_len]
    call print_char
    jmp .input_num
.backspace:
    cmp byte [num_buffer_len], 0
    je .input_num
    dec di
    dec byte [num_buffer_len]
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .input_num
.process:
    mov byte [di], 0
    call string_to_int
    cmp byte [user_input], 0
    jb .invalid
    cmp byte [user_input], 100
    ja .invalid
    mov byte [input_valid_flag], 1
    ret
.invalid:
    mov byte [input_valid_flag], 0
    ret

string_to_int:
    mov si, num_buffer
    xor ax, ax
    xor cx, cx
.convert:
    mov cl, [si]
    cmp cl, 0
    je .done
    sub cl, '0'
    mov bl, 10
    mul bl
    add al, cl
    inc si
    jmp .convert
.done:
    mov [user_input], al
    ret

print_number:
    pusha
    mov cx, 0
    mov bx, 10
.divide:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide
.print:
    pop dx
    add dl, '0'
    mov al, dl
    call print_char
    loop .print
    popa
    ret

; ============= КАЛЬКУЛЯТОР =============
calc_program:
    mov ax, 0x0003
    int 0x10
    mov ah, 0x06
    mov al, 0
    mov bh, 0x17
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov dh, 2
    mov dl, 28
    call set_cursor
    mov si, calc_title
    call print_str
    mov dh, 5
    mov dl, 10
    call set_cursor
    mov si, calc_prompt1
    call print_str
    call read_number
    mov bx, ax
    mov dh, 7
    mov dl, 10
    call set_cursor
    mov si, calc_prompt_op
    call print_str
    call read_operator
    mov byte [operator], al
    mov dh, 9
    mov dl, 10
    call set_cursor
    mov si, calc_prompt2
    call print_str
    call read_number
    mov cx, ax
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, calc_result
    call print_str
    mov al, [operator]
    cmp al, '+'
    je .add
    cmp al, '-'
    je .sub
    cmp al, '*'
    je .mul
    cmp al, '/'
    je .div
    jmp .op_error
.add:
    add bx, cx
    mov ax, bx
    call print_number
    jmp .calc_end
.sub:
    sub bx, cx
    mov ax, bx
    call print_number
    jmp .calc_end
.mul:
    mov ax, bx
    mul cx
    test dx, dx
    jnz .overflow
    call print_number
    jmp .calc_end
.div:
    cmp cx, 0
    je .div_zero
    mov ax, bx
    xor dx, dx
    div cx
    call print_number
    test dx, dx
    jz .calc_end
    mov si, calc_remainder
    call print_str
    mov ax, dx
    call print_number
    jmp .calc_end
.op_error:
    mov si, calc_error_op
    call print_str
    jmp .calc_end
.overflow:
    mov si, calc_error_overflow
    call print_str
    jmp .calc_end
.div_zero:
    mov si, calc_error_divzero
    call print_str
.calc_end:
    mov dh, 16
    mov dl, 10
    call set_cursor
    mov si, calc_anykey
    call print_str
    call wait_any_key
    ret

read_number:
    push bx
    push cx
    push dx
    mov di, number_input
    mov byte [number_len], 0
    mov cx, 6
.clear:
    mov byte [di], 0
    inc di
    loop .clear
    mov di, number_input
.input:
    call getchar_layout
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    cmp al, '0'
    jb .input
    cmp al, '9'
    ja .input
    cmp byte [number_len], 5
    jae .input
    stosb
    inc byte [number_len]
    call print_char
    jmp .input
.backspace:
    cmp byte [number_len], 0
    je .input
    dec di
    dec byte [number_len]
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .input
.done:
    mov byte [di], 0
    mov si, number_input
    xor ax, ax
    xor bx, bx
    mov cx, 10
.convert:
    mov bl, [si]
    cmp bl, 0
    je .convert_done
    sub bl, '0'
    mul cx
    add ax, bx
    inc si
    jmp .convert
.convert_done:
    pop dx
    pop cx
    pop bx
    ret

read_operator:
    push bx
    push cx
    push dx
.input:
    call getchar_layout
    cmp al, '+'
    je .valid
    cmp al, '-'
    je .valid
    cmp al, '*'
    je .valid
    cmp al, '/'
    je .valid
    jmp .input
.valid:
    call print_char
    pop dx
    pop cx
    pop bx
    ret

; ============= ОБРАБОТКА КОМАНД =============
process_command:
    ; Очистка области вывода
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0D01
    mov dx, 0x154E
    int 0x10
    mov dh, 13
    mov dl, 1
    call set_cursor

    cmp byte [command_buffer], 0
    je .exit

    mov si, command_buffer
    mov di, cmd_ls
    call compare_strings
    jc .do_ls

    mov si, command_buffer
    mov di, cmd_write_to
    call compare_strings_prefix
    jc .do_write_to

    mov si, command_buffer
    mov di, cmd_write_in
    call compare_strings_prefix
    jc .do_write_in

    mov si, command_buffer
    mov di, cmd_cd_dotdot
    call compare_strings
    jc .do_cd_up

    mov si, command_buffer
    mov di, cmd_cd
    call compare_strings_prefix
    jc .do_cd

    mov si, command_buffer
    mov di, cmd_mkdir
    call compare_strings_prefix
    jc .do_mkdir

    mov si, command_buffer
    mov di, cmd_clr
    call compare_strings
    jc .clear_screen

    mov si, command_buffer
    mov di, cmd_reboot
    call compare_strings
    jc .reboot

    mov si, command_buffer
    mov di, cmd_help
    call compare_strings
    jc .show_help

    mov si, command_buffer
    mov di, cmd_sysinfo
    call compare_strings
    jc .show_sysinfo

    mov si, command_buffer
    mov di, cmd_guess
    call compare_strings
    jc .start_guess_game

    mov si, command_buffer
    mov di, cmd_calc
    call compare_strings
    jc .calc

    mov si, command_buffer
    mov di, cmd_time
    call compare_strings
    jc .show_time

    mov si, command_buffer
    mov di, cmd_date
    call compare_strings
    jc .show_date

    mov si, unknown_cmd
    call print_str
    jmp .exit

.do_ls:
    call list_files
    jmp .exit

.do_write_to:
    mov si, command_buffer + 9
    call extract_filename
    jc .valid1
    jmp .invalid_name
.valid1:
    call create_file
    jmp .exit

.do_write_in:
    mov si, command_buffer + 9
    call extract_filename
    jc .valid2
    jmp .invalid_name
.valid2:
    call open_file
    jmp .exit

.do_cd_up:
    call cd_up_command
    jmp .exit

.do_cd:
    call cd_command
    jmp .exit

.do_mkdir:
    call mkdir_command
    jmp .exit

.invalid_name:
    mov si, err_invalid_name
    call print_str
    jmp .exit

.clear_screen:
    call init_interface
    jmp .exit

.reboot:
    int 0x19

.show_help:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0201
    mov dx, 0x164E
    int 0x10
    mov dh, 2
    mov dl, 1
    call set_cursor
    mov si, help_full
    call print_str
    jmp .exit

.show_sysinfo:
    mov si, sysinfo_full
    call print_str
    jmp .exit

.start_guess_game:
    call guess_game
    call init_interface
    jmp .exit

.calc:
    call calc_program
    call init_interface
    jmp .exit

.show_time:
    call get_time_string
    mov si, time_str
    call print_str
    call new_line
    jmp .exit

.show_date:
    call get_date_string
    mov si, date_str
    call print_str
    call new_line

.exit:
    mov dh, 22
    mov dl, 1
    call set_cursor
    mov si, press_any_key
    call print_str
    call wait_any_key
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0D01
    mov dx, 0x174E
    int 0x10
    ret

; ============= ДАННЫЕ =============
title_text     db ' BarniOS - Home Edition ', 0
menu_file      db ' File ', 0
menu_edit      db ' Edit ', 0
menu_view      db ' View ', 0
menu_help      db ' Help ', 0
status_text    db ' Ready | BarniOS Professional | Command Line Interface ', 0
caps_status    db ' CAPS ', 0

%ifdef RUSSIAN
welcome_msg    db 'Добро пожаловать в BarniOS Professional, ', 0
system_info    db 'Система: BarniOS v2.0 | Память: 640KB | Диск: 1.44MB', 0
commands_list  db 'Доступные команды: введите help для списка команд', 0
press_any_key  db 'Нажмите любую клавишу для продолжения...', 0

help_full db 'Доступные команды:', 13, 10
          db '  clr     - Очистить экран', 13, 10
          db '  reboot  - Перезагрузить', 13, 10
          db '  help    - Эта справка', 13, 10
          db '  sysinfo - Информация о системе', 13, 10
          db '  guess   - Игра "Угадай число"', 13, 10
          db '  calc    - Калькулятор', 13, 10
          db '  time    - Показать время', 13, 10
          db '  date    - Показать дату', 13, 10
          db '  ls      - Список файлов', 13, 10
          db '  write to <file> - Создать/редактировать', 13, 10
          db '  write in <file> - Открыть файл', 13, 10
          db '  cd <dir> - Сменить директорию', 13, 10
          db '  cd ..    - На уровень вверх', 13, 10
          db '  mkdir <dir> - Создать директорию', 13, 10, 0

unknown_cmd    db 'Ошибка: Неизвестная команда. Введите "help" для списка команд.', 0

err_no_free   db 'Ошибка: Нет свободных слотов для файлов!', 13,10,0
err_not_found db 'Ошибка: Файл не найден!', 13,10,0
err_readonly  db 'Предупреждение: Этот файл доступен только для чтения.', 13,10,0
err_invalid_name db 'Ошибка: Неверное имя файла.', 13,10,0
err_not_dir   db 'Ошибка: Не директория.', 13,10,0
err_cd_up     db 'Ошибка: Уже в корне.', 13,10,0

sysinfo_full   db '     === Информация о системе BarniOS ===', 13, 10
               db '         / \__', 13, 10
               db '        (    @\___', 13, 10
               db '       /        O', 13, 10
               db '      /   (_____/', 13, 10
               db '     /_____/   U', 13, 10
               db '     Copyright (C) BARNINO SYSTEMS & Barni Project Team', 13, 10
               db '     (2026), все права защищены.', 13, 10
               db '     BarniOS 2.3 с GraFase 2.0 BarnEl 2.4', 13, 10, 0

game_title      db '=== Игра "Угадай число" ===', 0
game_welcome    db 'Я загадал число от 0 до 100.', 0
game_instructions db 'Попробуй угадать его за как можно меньше попыток!', 0
game_attempt    db 'Попыток: ', 0
game_prompt     db 'Твоё число: ', 0
game_too_low    db 'Нет, моё число больше. Попробуй ещё!', 0
game_too_high   db 'Нет, моё число меньше. Попробуй ещё!', 0
game_correct    db 'Поздравляю! Ты угадал число за ', 0
game_congrats   db ' попыток!', 0
game_invalid    db 'Пожалуйста, введите число от 0 до 100.', 0
game_exit_msg   db 'Нажмите любую клавишу для возврата в BarniOS...', 0

calc_title      db '=== Простой калькулятор ===', 0
calc_prompt1    db 'Введите первое число (0-65535): ', 0
calc_prompt_op  db 'Введите оператор (+, -, *, /): ', 0
calc_prompt2    db 'Введите второе число: ', 0
calc_result     db 'Результат: ', 0
calc_error_op   db 'Неверный оператор!', 0
calc_error_divzero db 'Ошибка: Деление на ноль!', 0
calc_error_overflow db 'Ошибка: Переполнение!', 0
calc_remainder  db ' остаток ', 0
calc_anykey     db 'Нажмите любую клавишу для возврата в BarniOS...', 0

password_prompt db 'Введите пароль: ', 0
password_error  db 13,10, 'Неверный пароль! Нажмите любую клавишу для перезагрузки.', 13,10,0
%else
welcome_msg    db 'Welcome to BarniOS Professional, ', 0
system_info    db 'System: BarniOS v2.0 | Memory: 640KB | Disk: 1.44MB', 0
commands_list  db 'Available commands: type help to show list of commands', 0
press_any_key  db 'Press any key to continue...', 0

help_full db 'Available commands:', 13, 10
          db '  clr     - Clear screen', 13, 10
          db '  reboot  - Restart', 13, 10
          db '  help    - This help', 13, 10
          db '  sysinfo - System info', 13, 10
          db '  guess   - Number game', 13, 10
          db '  calc    - Calculator', 13, 10
          db '  time    - Show time', 13, 10
          db '  date    - Show date', 13, 10
          db '  ls      - List files', 13, 10
          db '  write to <file> - Create/edit', 13, 10
          db '  write in <file> - Open file', 13, 10
          db '  cd <dir> - Change directory', 13, 10
          db '  cd ..    - Go up', 13, 10
          db '  mkdir <dir> - Create directory', 13, 10, 0

unknown_cmd    db 'Error: Unknown command. Type "help" for available commands.', 0

err_no_free   db 'Error: No free file slots!', 13,10,0
err_not_found db 'Error: File not found!', 13,10,0
err_readonly  db 'Warning: This file is read-only.', 13,10,0
err_invalid_name db 'Error: Invalid filename.', 13,10,0
err_not_dir   db 'Error: Not a directory.', 13,10,0
err_cd_up     db 'Error: Already in root.', 13,10,0

sysinfo_full   db '     === BarniOS System Information ===', 13, 10
               db '         / \__', 13, 10
               db '        (    @\___', 13, 10
               db '       /        O', 13, 10
               db '      /   (_____/', 13, 10
               db '     /_____/   U', 13, 10
               db '     Copyright (C) BARNINO SYSTEMS & Barni Project Team', 13, 10
               db '     (2026), all rights reserved.', 13, 10
               db '     BarniOS 2.3 with GraFase 2.0 BarnEl 2.4', 13, 10, 0

game_title      db '=== Number Guessing Game ===', 0
game_welcome    db 'I am thinking of a number between 0 and 100.', 0
game_instructions db 'Try to guess the number in as few attempts as possible!', 0
game_attempt    db 'Attempts: ', 0
game_prompt     db 'Your guess: ', 0
game_too_low    db 'No, my number is higher than that. Try again!', 0
game_too_high   db 'No, my number is lower than that. Try again!', 0
game_correct    db 'Congratulations! You guessed my number in ', 0
game_congrats   db ' attempts!', 0
game_invalid    db 'Please enter a valid number between 0 and 100.', 0
game_exit_msg   db 'Press any key to return to BarniOS...', 0

calc_title      db '=== Simple Calculator ===', 0
calc_prompt1    db 'Enter first number (0-65535): ', 0
calc_prompt_op  db 'Enter operator (+, -, *, /): ', 0
calc_prompt2    db 'Enter second number: ', 0
calc_result     db 'Result: ', 0
calc_error_op   db 'Invalid operator!', 0
calc_error_divzero db 'Error: Division by zero!', 0
calc_error_overflow db 'Error: Overflow!', 0
calc_remainder  db ' remainder ', 0
calc_anykey     db 'Press any key to return to BarniOS...', 0

password_prompt db 'Please type password: ', 0
password_error  db 13,10, 'Wrong password! Press any key to reboot.', 13,10,0
%endif

; ---------- СТРОКИ КОМАНД (добавлены) ----------
cmd_ls          db 'ls', 0
cmd_write_to    db 'write to ', 0
cmd_write_in    db 'write in ', 0
cmd_cd          db 'cd ', 0
cmd_cd_dotdot   db 'cd ..', 0
cmd_mkdir       db 'mkdir ', 0
cmd_clr         db 'clr', 0
cmd_reboot      db 'reboot', 0
cmd_help        db 'help', 0
cmd_sysinfo     db 'sysinfo', 0
cmd_guess       db 'guess', 0
cmd_calc        db 'calc', 0
cmd_time        db 'time', 0
cmd_date        db 'date', 0

; ---------- БУФЕРЫ ВРЕМЕНИ ----------
time_str        db '00:00', 0
date_str        db '00.00.0000', 0

; ---------- БУФЕРЫ КОМАНД ----------
command_buffer  times 64 db 0
cmd_length      db 0

; ---------- ПЕРЕМЕННЫЕ ИГР ----------
secret_num      db 0
attempt_count   dw 0
user_input      db 0
input_valid_flag db 0
num_buffer      times 4 db 0
num_buffer_len  db 0

; ---------- ПЕРЕМЕННЫЕ КАЛЬКУЛЯТОРА ----------
operator        db 0
number_input    times 6 db 0
number_len      db 0

; ---------- ПЕРЕМЕННЫЕ ПАРОЛЯ И РУССКОЙ РАСКЛАДКИ ----------
username_str    db "__USERNAME__", 0
password_str    db "__PASSWORD__", 0

; ============= ФУНКЦИЯ ВВОДА С ПЕРЕКЛЮЧЕНИЕМ РАСКЛАДКИ =============
layout_flag db 0         ; 0 - EN, 1 - RU

; Таблица преобразования английских букв в русские (CP866)
; для строчных: a->а, b->б, ..., z->я
ru_lower_table:
    db 0xE0, 0xE2, 0xE7, 0xE5, 0xE4, 0xE1, 0xE3, 0xE8, 0xE9, 0xEB, 0xEC, 0xED
    db 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9
    db 0xFA, 0xFB
; для заглавных: A->А, B->Б, ..., Z->Я
ru_upper_table:
    db 0xC0, 0xC2, 0xC7, 0xC5, 0xC4, 0xC1, 0xC3, 0xC8, 0xC9, 0xCB, 0xCC, 0xCD
    db 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9
    db 0xDA, 0xDB

getchar_layout:
    push bx
    push cx
    push dx
    push si
    push di
.loop:
    xor ax, ax
    int 0x16
    ; Проверяем, не нажата ли клавиша Win (левая 0x5B, правая 0x5C)
    cmp ah, 0x5B
    je .toggle_layout
    cmp ah, 0x5C
    je .toggle_layout
    ; Если символ не ASCII (AL=0), повторяем
    cmp al, 0
    je .loop
    ; Если раскладка русская и символ – буква, преобразуем
    cmp byte [layout_flag], 1
    jne .done
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .check_upper
    ; строчная английская
    sub al, 'a'
    mov bx, ru_lower_table
    xlat
    jmp .done
.check_upper:
    cmp al, 'A'
    jb .done
    cmp al, 'Z'
    ja .done
    sub al, 'A'
    mov bx, ru_upper_table
    xlat
    jmp .done
.toggle_layout:
    xor byte [layout_flag], 1
    jmp .loop
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; ============= ЗАПРОС ПАРОЛЯ =============
password_login:
    pusha
    ; Очищаем область вывода (нижнюю часть)
    mov ah, 0x06
    mov al, 0
    mov bh, 0x70
    mov cx, 0x0A01
    mov dx, 0x164E
    int 0x10
    mov dh, 10
    mov dl, 10
    call set_cursor
    ; Приветствие
    mov si, welcome_msg
    call print_str
    mov si, username_str
    call print_str
    mov al, '!'
    call print_char
    call new_line
    ; Запрос пароля
    mov si, password_prompt
    call print_str
    ; Чтение пароля
    mov di, password_input
    mov cx, 0
.read_pass:
    call getchar_layout
    cmp al, 13          ; Enter
    je .check
    cmp al, 8           ; Backspace
    je .backspace
    cmp cx, 31          ; максимум 31 символ
    jae .read_pass
    stosb
    inc cx
    mov al, '*'
    call print_char
    jmp .read_pass
.backspace:
    test cx, cx
    jz .read_pass
    dec di
    dec cx
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .read_pass
.check:
    mov byte [di], 0
    call new_line
    ; Сравнение паролей
    mov si, password_input
    mov di, password_str
    call strcmp
    jc .ok
    ; Неверный пароль
    mov si, password_error
    call print_str
    call wait_any_key
    int 0x19            ; перезагрузка
.ok:
    popa
    ret

password_input  times 32 db 0
wait_any_key:
    xor ax, ax
    int 0x16
    ret

; ============= ЗАПОЛНЕНИЕ ДО 100 СЕКТОРОВ =============
times 51200-($-$$) db 0
