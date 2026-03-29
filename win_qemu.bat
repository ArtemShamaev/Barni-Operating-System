@echo off
title BarniOS Builder for Windows

echo === Installing NASM ===
winget install -e --id NASM.NASM
if %errorlevel% neq 0 (
    echo Please install NASM manually from https://www.nasm.us/
    pause
    exit /b 1
)

echo === Installing QEMU ===
winget install -e --id QEMU.QEMU
if %errorlevel% neq 0 (
    echo Please install QEMU manually from https://www.qemu.org/
    pause
    exit /b 1
)

echo === Checking source files ===
if not exist boot.asm (
    echo boot.asm not found!
    pause
    exit /b 1
)
if not exist kernel.asm (
    echo kernel.asm not found!
    pause
    exit /b 1
)

echo === Assembling bootloader ===
nasm -f bin boot.asm -o boot.bin
if %errorlevel% neq 0 (
    echo Bootloader assembly failed!
    pause
    exit /b 1
)

echo === Assembling kernel ===
nasm -f bin kernel.asm -o kernel.bin
if %errorlevel% neq 0 (
    echo Kernel assembly failed!
    pause
    exit /b 1
)

echo === Creating OS image ===
copy /b boot.bin + kernel.bin os-image.bin > nul
if %errorlevel% neq 0 (
    echo Failed to create image!
    pause
    exit /b 1
)

echo === Launching QEMU ===
qemu-system-x86_64 -drive format=raw,file=os-image.bin -m 32 -rtc base=localtime

pause
