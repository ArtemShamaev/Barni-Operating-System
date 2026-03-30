# ==================== BarniOS Makefile ====================
# Цели:
#   make download   - установить зависимости (nasm, qemu)
#   make config     - настроить имя пользователя и пароль
#   make compile    - собрать загрузчик и ядро
#   make run        - запустить в QEMU
#   make clean      - удалить временные файлы
#   make all        = compile + run
# ===========================================================

NASM    = nasm
QEMU    = qemu-system-x86_64
BOOT    = boot.asm
KERNEL  = kernel.asm
BOOT_BIN = boot.bin
KERNEL_BIN = kernel.bin
OS_IMAGE = os-image.bin
CONFIG  = config.txt
BOOT_CONFIG = boot_config.inc

.PHONY: all download config compile run clean

all: compile run

download:
	@echo "==> Installing dependencies..."
	@if command -v apt > /dev/null; then \
		sudo apt update && sudo apt install -y nasm qemu-system-x86; \
	elif command -v pacman > /dev/null; then \
		sudo pacman -S --noconfirm nasm qemu-full; \
	elif command -v urpmi > /dev/null; then \
		sudo urpmi --auto nasm qemu; \
	elif command -v choco > /dev/null; then \
		echo "Windows detected. Please ensure NASM and QEMU are installed via choco."; \
		choco install nasm qemu; \
	else \
		echo "Unsupported system. Please install NASM and QEMU manually."; \
		exit 1; \
	fi

config:
	@echo "==> Running configuration script..."
	@chmod +x config.sh
	@./config.sh

$(BOOT_CONFIG): $(CONFIG)
	@echo "==> Generating boot configuration..."
	@echo "; Auto-generated boot config" > $@
	@echo "USERNAME_STR db \"`sed -n '1p' $(CONFIG)`\", 0" >> $@
	@echo "PASSWORD_STR db \"`sed -n '2p' $(CONFIG)`\", 0" >> $@

compile: $(BOOT_CONFIG) $(BOOT) $(KERNEL)
	@echo "==> Assembling bootloader..."
	$(NASM) -f bin $(BOOT) -o $(BOOT_BIN)
	@echo "==> Preparing kernel (insert username)..."
	@sed "s/__USERNAME__/`sed -n '1p' $(CONFIG)`/g" $(KERNEL) > kernel_pre.asm
	@echo "==> Assembling kernel..."
	$(NASM) -f bin kernel_pre.asm -o $(KERNEL_BIN)
	@echo "==> Creating OS image..."
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMAGE)
	@echo "==> Build complete!"

run: compile
	@echo "==> Launching BarniOS in QEMU..."
	$(QEMU) -drive format=raw,file=$(OS_IMAGE) -m 32 -rtc base=localtime

clean:
	@echo "==> Cleaning up..."
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(OS_IMAGE) $(BOOT_CONFIG) kernel_pre.asm
