#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[installer]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; exit 1; }

# 1. Network Check
log "Checking network connectivity..."
if ! ping -c 1 google.com &> /dev/null; then
  log "Network not found. Launching iwctl..."
  iwctl
fi

if ! ping -c 1 google.com &> /dev/null; then
  error "Still no network. Please configure network manually and run this script again."
fi

# 2. Disk Selection (Simple TUI)
log "Select installation disk:"
DISK=$(lsblk -dno NAME,SIZE,MODEL | gum choose --header "Select Disk" | awk '{print $1}')
if [[ -z "$DISK" ]]; then error "No disk selected."; fi
DISK="/dev/$DISK"

# 3. User Configuration
USERNAME=$(gum input --placeholder "username" --prompt "User: ")
PASSWORD=$(gum input --password --placeholder "password" --prompt "Pass: ")
HOSTNAME=$(gum input --placeholder "hostname" --value "archlinux" --prompt "Host: ")

# 4. Generate Archinstall Config
# Minimal, sane defaults + your selections
cat <<EOF > user_configuration.json
{
    "archinstall-language": "English",
    "audio_config": { "audio": "pipewire" },
    "bootloader": "systemd-boot",
    "disk_config": {
        "config_type": "default_layout",
        "device_modifications": [
            {
                "device": "$DISK",
                "wipe": true
            }
        ]
    },
    "hostname": "$HOSTNAME",
    "kernels": [ "linux" ],
    "mirror_config": { "mirror_regions": { "United States": ["https://mirrors.kernel.org/archlinux/"] } },
    "network_config": { "type": "networkmanager" },
    "packages": [ "base", "base-devel", "git", "vim", "wget", "curl" ],
    "profile_config": { "profile": { "name": "minimal" } },
    "user_credentials": {
        "root_password": "$PASSWORD",
        "users": {
            "$USERNAME": {
                "password": "$PASSWORD",
                "sudo": true
            }
        }
    },
    "version": "2.5.0"
}
EOF

# 5. Run Archinstall
log "Starting Arch Linux installation..."
archinstall --config user_configuration.json --silent

# 6. Post-Install: Bootstrap Dotfiles
log "Bootstrapping dotfiles..."
cat <<EOF > /mnt/post_install.sh
#!/bin/bash
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/nopasswd
su - $USERNAME -c "curl -L https://raw.githubusercontent.com/Coding4Hours/dotfiles/refs/heads/main/install.sh | bash"
rm /etc/sudoers.d/nopasswd
EOF
chmod +x /mnt/post_install.sh

arch-chroot /mnt /post_install.sh

log "Installation Complete! Rebooting in 5 seconds..."
sleep 5
reboot
