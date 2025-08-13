#!/bin/bash
echo "Starting automated archinstall with default config..."

archinstall

if [ -d /mnt ]; then
  cp /root/install_dotfiles.sh /mnt/root/
  arch-chroot /mnt /bin/bash /root/install_dotfiles.sh
fi

echo "Autoinstall finished."
