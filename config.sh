#!/bin/bash
# BarniOS Configuration Script
# Сохраняет имя пользователя и пароль в config.txt

read -p "Enter username: " username
read -s -p "Enter password: " password
echo
echo "Saving configuration..."
echo "$username" > config.txt
echo "$password" >> config.txt
echo "Configuration saved."
