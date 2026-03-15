#!/bin/bash
set -e

# 1️⃣ Create builduser and give sudo permissions
useradd -m builduser
echo 'builduser ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers

# 2️⃣ Install base-devel and git (required for building AUR packages)
pacman -Syu --noconfirm base-devel git

# 3️⃣ Switch to builduser and install yay
sudo -iu builduser bash <<'EOF'
# Go to tmp and clone yay
cd /tmp
if [ -d yay ]; then
    rm -rf yay
fi
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
# 5️⃣ Setup .xinitrc to launch awesome WM
echo 'exec awesome' > /home/builduser/.xinitrc

# 6️⃣ Setup .bash_profile to start X on first TTY
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> /home/builduser/.bash_profile

# 7️⃣ Correct ownership and permissions
chown builduser:builduser /home/builduser/.xinitrc /home/builduser/.bash_profile
chmod 644 /home/builduser/.xinitrc /home/builduser/.bash_profile

echo "✅ Setup complete. You can now log in as builduser and start your X session."
