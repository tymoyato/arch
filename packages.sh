#!/bin/bash

# Arch Linux Package Installer with Logging
# -----------------------------------------
# Installs every package the dotfiles (github.com/tymoyato/dotfiles) rely on,
# via pacman and paru (for AUR). Logs failed installations to failed_packages.log

# Install paru (AUR helper) if not already installed
if ! command -v paru &>/dev/null; then
    echo "[INSTALLING] paru (AUR helper)"
    sudo pacman -S --noconfirm --needed base-devel git
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
    (cd "$tmp_dir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp_dir"
fi

# File to log failed packages
LOG_FILE="$(dirname "$(realpath "$0")")/failed_packages.log"
: > "$LOG_FILE"  # Clear previous log

# List of packages
PACKAGES=(
    git curl mercurial make binutils gcc bison wmctrl util-linux zlib
    shellcheck shfmt awesome rofi picom xclip flameshot xdotool fish
    eza btop atuin less bat fzf zoxide neovim ripgrep unzip go
    lazygit lxappearance xorg-xinit xorg-server kitty openssh xorg-setxkbmap
    noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-meslo-nerd ttf-nerd-fonts-symbols-mono
    ttf-liberation ttf-dejavu alsa-utils
    playerctl pipewire pipewire-alsa pipewire-pulse pipewire-jack
    xorg-xrandr rbenv ruby-build libyaml
    nvm fisher difftastic lazydocker vlc nautilus discord pacman-contrib fastfetch dmenu
    bluez bluez-utils feh jq bc docker speedtest-cli translate-shell sound-theme-freedesktop wget tree-sitter tree-sitter-cli
    tmux fd direnv git-delta github-cli libnotify ddcutil i2c-tools python rofimoji zed obsidian
)

# NVIDIA driver only on machines with an NVIDIA GPU (PCI vendor 0x10de).
# ponytail: nvidia-open covers Turing (GTX 16xx / RTX 20xx) and newer; older cards need AUR nvidia-580xx-dkms
if grep -qs 0x10de /sys/bus/pci/devices/*/vendor; then
    PACKAGES+=(nvidia-open-dkms linux-headers nvidia-utils nvidia-settings)
fi

# AUR-only packages
# shellcheck disable=SC2034  # used via nameref in install_all
AUR_PACKAGES=(brave-bin light bsdmainutils betterlockscreen greenclip sesh-bin bruno-bin)

# Install a whole list in one transaction; if that fails, retry one by one
# so a single bad package doesn't block the rest and gets logged.
# Usage: install_all <array-name> <installer...>
install_all() {
    local -n list=$1
    shift
    "$@" -S --noconfirm --needed "${list[@]}" && return
    for pkg in "${list[@]}"; do
        if "$@" -S --noconfirm --needed "$pkg"; then
            echo "[INSTALLED] $pkg"
        else
            echo "$pkg" >> "$LOG_FILE"
            echo "[FAILED] $pkg"
        fi
    done
}

install_all PACKAGES sudo pacman
install_all AUR_PACKAGES paru

echo "Installation complete!"
if [[ -s "$LOG_FILE" ]]; then
    echo "Some packages failed to install. Check $LOG_FILE for details."
else
    echo "All packages installed successfully!"
fi

# Enable fstrim for SSD health and performance
sudo systemctl enable --now fstrim.timer
echo "[SET] fstrim.timer enabled"

# Enable weekly pacman cache cleanup (keeps last 3 versions)
sudo systemctl enable paccache.timer
echo "[SET] paccache.timer enabled"

# Docker daemon + run docker without sudo (awesome docker widgets poll it)
sudo systemctl enable docker.service
sudo usermod -aG docker "$USER"
echo "[SET] docker enabled, $USER added to docker group"

# Bluetooth (rofi bluetooth script)
sudo systemctl enable bluetooth.service
echo "[SET] bluetooth enabled"

# DDC/CI monitor brightness (awesome brightness widget uses ddcutil)
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo usermod -aG i2c "$USER"
echo "[SET] i2c-dev loaded at boot, $USER added to i2c group"

# Lower swappiness for better performance with enough RAM
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo "[SET] vm.swappiness=10"

# Replace relatime with noatime on btrfs partitions to reduce SSD writes
sudo sed -i 's/\brelatime\b/noatime/g' /etc/fstab
echo "[SET] noatime on btrfs partitions"

# Disable accessibility service (not needed, reduces startup overhead)
systemctl --user disable --now at-spi-dbus-bus.service 2>/dev/null
echo "[SET] at-spi disabled"

# Set fish as default shell
if command -v fish &>/dev/null; then
    fish_path=$(command -v fish)
    grep -qF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
    sudo usermod -s "$fish_path" "$USER"
    echo "[SET] fish as default shell"
fi

echo "Log out and back in for group changes (docker, i2c) to apply."
