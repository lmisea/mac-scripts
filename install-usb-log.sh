#!/bin/bash
# This script is for installing and setting up the usb-log.sh script and the udev rule.
# Execute this script before using the usb-log.sh script.
# Written by LP (Llama Perpetua) - 2023.

# Replace "/home/*/usb-log" with "$HOME/usb-log" in the usb-log.sh script
echo "Replacing "/home/*/usb-log" with "$HOME/usb-log" in usb-log.sh"
sed -i "s|/home/*/usb-log|$HOME/usb-log|g" $(realpath usb-log.sh)

# Replace "/run/user/1000" with "/run/user/$(id -u)" in the usb-log.sh script
echo "Replacing "/run/user/1000" with "/run/user/$(id -u)" in usb-log.sh"
sed -i "s|/run/user/1000|/run/user/$(id -u)|g" $(realpath usb-log.sh)

# Setting up the udev rule
echo "Setting up the udev rule"
sudo cp $(realpath 99-usb-log.rules) /etc/udev/rules.d/99-usb-log.rules
sudo udevadm control --reload-rules

echo "Done!"
