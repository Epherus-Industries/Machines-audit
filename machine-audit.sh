#!/bin/bash
set -euo pipefail
set -x  # Show every command for maximum transparency

# Ensure sudo upfront
if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script as root (sudo)."
  exit 1
fi

# Dependencies
apt update
apt install -y lshw smartmontools dmidecode usbutils tpm2-tools inxi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="/root/machine_audit_$TIMESTAMP.txt"
exec > >(tee "$OUTPUT") 2>&1

echo "===== 🧠 CPU ====="
lscpu

echo -e "\n===== 🧬 RAM ====="
free -h
dmidecode --type 17

echo -e "\n===== 💾 STORAGE ====="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
fdisk -l
for disk in /dev/sd?; do
  smartctl -H "$disk" || true
done

echo -e "\n===== 🔌 NETWORK ====="
ip link show
lshw -class network

echo -e "\n===== 🧱 MOTHERBOARD ====="
dmidecode -t baseboard

echo -e "\n===== 🧰 GPU ====="
lspci | grep -Ei 'vga|3d|display'

echo -e "\n===== 🧱 OS Info ====="
lsb_release -a || cat /etc/os-release
uname -a

echo -e "\n===== 🔐 TPM ====="
tpm2_getcap properties-fixed || echo "TPM not detected or not configured."

echo -e "\n===== 🔋 POWER (Laptop) ====="
upower -i $(upower -e | grep BAT) | grep -E "state|to\ full|percentage" || echo "Not a laptop or no battery."

echo -e "\n===== 🧪 USB Devices ====="
lsusb

echo -e "\n===== 🔍 INXI QUICK SUMMARY ====="
inxi -Faz
