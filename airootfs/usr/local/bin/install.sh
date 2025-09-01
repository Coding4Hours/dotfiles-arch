
#!/bin/bash
echo "Installing dotfiles inside chroot..."

# Make sure git is installed in your installed system!
if ! command -v git >/dev/null 2>&1; then
  echo "Git not found! Installing git..."
  pacman -Sy --noconfirm git
fi

cd /root
if [ -d dotfiles ]; then
  echo "dotfiles directory exists. Pulling latest changes..."
  cd dotfiles && git pull
else
  git clone https://github.com/coding4hours/dotfiles.git
  cd dotfiles
fi

chmod +x ./install.sh
./install.sh
