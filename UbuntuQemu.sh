#!/bin/bash
set -e

echo "=== Updating package list ==="
sudo apt update

echo "=== Installing NASM and QEMU ==="
sudo apt install -y nasm qemu-system-x86

echo "=== Checking source files ==="
if [ ! -f boot.asm ]; then
    echo "boot.asm not found!"
    exit 1
fi
if [ ! -f kernel.asm ]; then
    echo "kernel.asm not found!"
    exit 1
fi

echo "=== Assembling bootloader ==="
nasm -f bin boot.asm -o boot.bin

echo "=== Assembling kernel ==="
nasm -f bin kernel.asm -o kernel.bin

echo "=== Creating OS image ==="
cat boot.bin kernel.bin > os-image.bin

echo "=== Launching QEMU ==="
qemu-system-x86_64 -drive format=raw,file=os-image.bin -m 32 -rtc base=localtime
