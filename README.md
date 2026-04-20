# Barni Operating System
# Установка
Для установки нужна целевая система ___Ubuntu, Linux Mint, Dedian___ или подобная.
Откройте ___"Терменал"___ и выполните

```
sudo apt update
sudo apt install qemu-system-x86 qemu-utils make mtools dosfstools make nasm
git clone https://github.com/ArtemShamaev/Barni-Operating-System.git
```
## Всё, установка завершена.

# Запись на реальный накопитель
Для записи на реальный диск выполните: 
```
make download
make config
```
После введите имя пользователя и пароль (введеный пароль не отображается).
Затем введите:
```
make compile
make write
```
У Вас спросят на какой диск Вы хотите установить. Вот пример вывода команды:
```
==> Assembling bootloader...
nasm -f bin boot.asm -o boot.bin
==> Preparing kernel (insert username)...
==> Assembling kernel...
nasm -f bin kernel_pre.asm -o kernel.bin
==> Creating OS image...
cat boot.bin kernel.bin > os-image.bin
==> Build complete!
==> Preparing to write BarniOS to a physical disk...
Available disks (all data on selected disk will be destroyed!):
sda      28,9G FLASH DRIVE
sdb       1,8T TOSHIBA MQ04UBD200
nvme0n1 476,9G YMTC PC300-512GB-B

Enter disk number (e.g., 1 for sda, 2 for sdb...): 1
You selected: /dev/sdb

WARNING: All data on /dev/sdb will be IRREVERSIBLY LOST!
Are you sure? Type 'yes' to continue: yes
Final confirmation: type 'YES' to proceed: YES
Writing image to /dev/sdb...
101+0 records in
101+0 records out
51712 bytes (52 kB, 50 KiB) copied, 3,08247 s, 16,8 kB/s
Success! BarniOS has been written to /dev/sda.
You can now boot from this disk (ensure CSM/Legacy mode is enabled).
```
## ВНИМАНИЕ: ПОСЛЕ ПОТВЕЖДЕНИЯ ВСЕ ДАННЫЕ НА НАКОПИТЕЛЕ БУДУТ УНИЧТОЖЕННЫ БЕЗ ВОЗМОЖНОСТИ ВОССТАНОВЛЕНИЯ! Barnino Systems (C) не несет ответственность за Ваши действия! Будте аккуратны!


# Запуск, конфигурация, зависимости

Для конфигурации введите

```
make download
make config
```

После у Вас запросят имя пользователя BarniOS и его пароль.
Для запуска нужно написать

```
make compile
make run
```

Если Вы хотите сбросить пароль и пользователя, введите

```
make clean
```

## Настройка завершена, переходите далее.


# Как работать с Barnino Shell?

Командная строка BarniOS поддерживает разные команды.
```
help - Помощь и обозначение команд
clr - Очистить экран от мусора
reboot - Перезагрузка. Сотрет всё файлы, созданные за время работы
guess - Игра "Угадай Число От 0 До 100"
calc - Калькулятор
time - Время по часам BIOS
date - Дата по часам BIOS
ls - Файлы в директории
write to имя-файла - Создать и редактировать в файл
write in ммя-файла - Открыть и редактировать файл
cd имя - Перейти в папку
cd .. - Перейти в род. папку (не реализовано)
mkdir имя - созадть папку.
```
# Текстовый редактор Write
![](https://github.com/ArtemShamaev/Barni-Operating-System/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-04-08%2016%3A25%3A20.png)
Нужно вводить текст. bacspace стирает только пробелы! Поэтому для стирания нужно: подвинуть курсор на стираемый символ с помощью стрелок, нажать пробел, нажать bacspace. По нажатию на esc файл сохраняется, и редактор закроется.

# Guess The Number Game
![](https://github.com/ArtemShamaev/Barni-Operating-System/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-04-08%2016%3A35%3A12.png)
Вам нужно отгадать число, загаданное компьютером от 0 до 100. Если Вы не угадали, то даётся подсказка ***No, my number higer than that. Try again***, т.е. число, которое загадал компьютер ***БОЛЬШЕ***, чем которое написали Вы. Если вывелось ***No, my number higer than that. Try again***, то компьютер загадал меньшее число.

# Пути и приглашение ввода
![](https://github.com/ArtemShamaev/Barni-Operating-System/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-04-08%2018%3A25%3A09.png)

На предпоследней строчке Вы видите приглашение ввода. Оно состоит из диска системы (в разных версиях - разное). К сожалению вложенные папки не очень хорошо обрабатываются. Например

```
C:> mkdir Dog
C:> cd Dog
C:Dog\> mkdir Cat
C:DogCat\> 
```

Это не то, что мы ожидали. Команда ***ls*** выводит файлы, а не вложенные директории. Комнда cd .. не обрабатывется. В остальном ФС работает правильно. Прошу заметить, что ФС здесь ***виртуальная или же ФС для ОЗУ***. Поэтому при выключении и презагрузке все файлы удаляются.
# Лицензия на проект и его файлы

Этот проект распространяется под лицензией **Barni Operating System Personal License (BOS-PL) Version 1.0**.

- ✅ Бесплатно для личного некоммерческого использования
- ❌ Запрещено изменение, создание производных работ и распространение
- ❌ Запрещено коммерческое использование без отдельного соглашения

Подробные условия читайте в файле [LICENSE](LICENSE.md).
# Спасибо, что используете Barni Operating System и др. продукты Copyright (C) BARNINO SYSTEMS. Смотрите подробный обзор на каждую версию на [Youtube-канале Barnino Channel](https://www.youtube.com/@barninochannel)
```
    / \__
   (    @\____
  /        O /
 /   (_____/
 /_____/   U
 Copyright (C) BARNINO SYSTEMS (2026), all rights reserved.
```
