#!/bin/bash

# --- USER INPUT ---
echo "This script will launch the installer and then configure your new system"
echo "to automatically install your dotfiles on the first boot."
echo

USERNAME="coding4hours"
DOTFILES_REPO_URL="https://github.com/Coding4Hours/dotfiles/"

if [ -z "$USERNAME" ] || [ -z "$DOTFILES_REPO_URL" ]; then
    echo "ERROR: Username and repository URL cannot be empty. Exiting."
    exit 1
fi

echo
echo "Great. The installer will now launch. Complete the installation as you normally would."
echo "IMPORTANT: When it finishes, UNCHECK 'Reboot now' and close the installer window."
echo "This script will then finish the setup."
echo
echo "Press Enter to launch the installer..."
read

# --- LAUNCH INSTALLER AND WAIT ---
calamares &
wait $!
echo
echo "Installer finished. Now setting up your dotfiles for the first boot..."

# --- TARGET SYSTEM PATH ---
TARGET_DIR="/mnt"
if [ ! -d "$TARGET_DIR/home/$USERNAME" ]; then
    echo "ERROR: Could not find the installed system at $TARGET_DIR/home/$USERNAME." >&2
    echo "Did the installation fail, or did you enter a different username?" >&2
    exit 1
fi

# --- CREATE THE DOTFILES INSTALL SCRIPT ON THE NEW SYSTEM ---
cat > "$TARGET_DIR/tmp/setup_dotfiles.sh" <<EOF
#!/bin/bash
# This script runs on the first boot of the new system to install dotfiles.

# Wait for an active internet connection
while ! ping -c 1 -W 1 github.com &>/dev/null; do sleep 1; done

# Install git
pacman -S --noconfirm git

# Run the rest of the commands as the new user
sudo -u $USERNAME bash <<'SUDO_CMD'
    # Clone the dotfiles repository
    git clone "$DOTFILES_REPO_URL" "/home/$USERNAME/.dotfiles"

    # If there's a setup/install script in the repo, run it
    if [ -f "/home/$USERNAME/.dotfiles/install.sh" ]; then
        bash "/home/$USERNAME/.dotfiles/install.sh"
    elif [ -f "/home/$USERNAME/.dotfiles/setup.sh" ]; then
        bash "/home/$USERNAME/.dotfiles/setup.sh"
    fi
SUDO_CMD

# --- Self-destruct sequence ---
# Disable and remove the service and this script to ensure it only runs once.
systemctl disable setup-dotfiles.service
rm -f /etc/systemd/system/setup-dotfiles.service /tmp/setup_dotfiles.sh
EOF

# --- CREATE THE SYSTEMD SERVICE ON THE NEW SYSTEM ---
cat > "$TARGET_DIR/etc/systemd/system/setup-dotfiles.service" <<EOF
[Unit]
Description=Install user dotfiles on first boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /tmp/setup_dotfiles.sh

[Install]
WantedBy=multi-user.target
EOF

# --- ENABLE THE SERVICE IN THE NEW SYSTEM ---
echo "Enabling the first-boot service..."
chmod +x "$TARGET_DIR/tmp/setup_dotfiles.sh"
arch-chroot "$TARGET_DIR" systemctl enable setup-dotfiles.service

echo
echo "--------------------------------------------------------"
echo "✅ Success! Your dotfiles will be installed automatically on the first boot."
echo "You can now reboot your computer."
echo "--------------------------------------------------------"
