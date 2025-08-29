#!/bin/bash
echo "Starting automated archinstall with default config..."
iwctl
archinstall

if [ -d /mnt ]; then
  cp /root/install_dotfiles.sh /mnt/root/
  arch-chroot /mnt /bin/bash /root/install_dotfiles.sh
fi

echo "Autoinstall finished."

# Run the automated installation
archinstall --config /root/user_configuration.json --creds /root/user_credentials.json --silent

# Mount the newly installed system's root partition to /mnt if not already mounted
# (archinstall usually leaves it mounted)

# Create a directory for our post-install script on the new system
mkdir -p /mnt/root/setup

# Copy the dotfiles setup script and the systemd service to the new system
cp /root/setup_dotfiles.sh /mnt/root/setup/
cp /root/dotfiles.service /mnt/etc/systemd/system/

# Enable the systemd service in the new system
arch-chroot /mnt systemctl enable dotfiles.service
