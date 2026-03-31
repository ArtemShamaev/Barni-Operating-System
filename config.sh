#!/bin/bash
# BarniOS Configuration Script
echo "BarniOS Configuration"
read -p "Enter username: " username
read -s -p "Enter password: " password
echo
echo "Select language:"
echo "1 - Russian"
echo "2 - English"
read -p "Choice (1/2): " lang
echo "$username" > config.txt
echo "$password" >> config.txt
echo "$lang" >> config.txt
echo "Configuration saved."
