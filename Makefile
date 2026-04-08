# ==================== BarniOS Makefile ====================
# Цели:
#   make download   - установить зависимости (nasm, qemu)
#   make config     - настроить имя пользователя и пароль
#   make compile    - собрать загрузчик и ядро
#   make run        - запустить в QEMU
#   make write      - записать образ на реальный диск (внимание! удалит данные)
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

.PHONY: all download config compile run write clean

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
		echo "Windows detected. Please install NASM and QEMU manually via choco."; \
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

# ---------- ЦЕЛЬ WRITE (запись на реальный диск) ----------
write: compile
	@echo "==> Preparing to write BarniOS to a physical disk..."
	@if ! command -v lsblk > /dev/null; then \
		echo "ERROR: 'lsblk' command not found. This target requires Linux with lsblk."; \
		echo "You can write manually using: sudo dd if=$(OS_IMAGE) of=/dev/sdX bs=512"; \
		exit 1; \
	fi
	@echo "Available disks (all data on selected disk will be destroyed!):"
	@lsblk -d -o NAME,SIZE,MODEL | grep -E '^(sd|hd|vd|nvme)' || (echo "No suitable disks found." && exit 1)
	@echo ""
	@read -p "Enter disk number (e.g., 1 for sda, 2 for sdb...): " DISK_NUM; \
	DISK_NAME=$$(lsblk -d -o NAME | grep -E '^(sd|hd|vd|nvme)' | sed -n "$${DISK_NUM}p"); \
	if [ -z "$$DISK_NAME" ]; then \
		echo "Invalid disk number."; \
		exit 1; \
	fi; \
	echo "You selected: /dev/$$DISK_NAME"; \
	echo ""; \
	echo "WARNING: All data on /dev/$$DISK_NAME will be IRREVERSIBLY LOST!"; \
	read -p "Are you sure? Type 'yes' to continue: " CONFIRM; \
	if [ "$$CONFIRM" != "yes" ]; then \
		echo "Aborted."; \
		exit 1; \
	fi; \
	read -p "Final confirmation: type 'YES' to proceed: " FINAL; \
	if [ "$$FINAL" != "YES" ]; then \
		echo "Aborted."; \
		exit 1; \
	fi; \
	echo "Writing image to /dev/$$DISK_NAME..."; \
	sudo dd if=$(OS_IMAGE) of=/dev/$$DISK_NAME bs=512 conv=fsync status=progress; \
	if [ $$? -eq 0 ]; then \
		echo "Success! BarniOS has been written to /dev/$$DISK_NAME."; \
		echo "You can now boot from this disk (ensure CSM/Legacy mode is enabled)."; \
	else \
		echo "Write failed. Try running 'make write' with sudo or check disk permissions."; \
		exit 1; \
	fi

clean:
	@echo "==> Cleaning up..."
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(OS_IMAGE) $(BOOT_CONFIG) kernel_pre.asm
