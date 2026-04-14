#!/bin/bash

# Arch Linux Package Installer with Logging
# -----------------------------------------
# This script installs a list of packages via pacman and paru (for AUR)
# Logs failed installations to failed_packages.log

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
LOG_FILE="failed_packages.log"
: > "$LOG_FILE"  # Clear previous log

# List of packages
PACKAGES=(
    git curl mercurial make binutils gcc bison wmctrl util-linux zlib
    shellcheck shfmt awesome rofi picom xclip flameshot xdotool fish
    eza btop atuin less bat fzf zoxide neovim ripgrep unzip go
    lazygit lxappearance xorg-xinit xorg-server kitty openssh xorg-setxkbmap
    noto-fonts-emoji nerd-fonts ttf-liberation ttf-dejavu alsa-utils
    playerctl pipewire pipewire-alsa pipewire-pulse pipewire-jack
    nvidia-dkms linux-headers nvidia-utils nvidia-settings xorg-xrandr rbenv ruby-build libyaml
    nvm fisher difftastic lazydocker vlc nautilus discord pacman-contrib fastfetch dmenu
    bluez bluez-utils feh jq bc docker speedtest-cli translate-shell sound-theme-freedesktop wget tree-sitter tree-sitter-cli
)

# Packages that are likely AUR-only
AUR_PACKAGES=("brave-browser" "light" "bsdmainutils" "i3lock-fancy" "greenclip" "rofimoji" "ttf-nerd-fonts-symbols-mono")

# Function to install packages via pacman
install_pacman_package() {
    local pkg="$1"
    if ! sudo pacman -S --noconfirm --needed "$pkg"; then
        echo "$pkg" >> "$LOG_FILE"
        echo "[FAILED] $pkg"
    else
        echo "[INSTALLED] $pkg"
    fi
}

# Function to install packages via paru (AUR)
install_aur_package() {
    local pkg="$1"
    if ! paru -S --noconfirm --needed "$pkg"; then
        echo "$pkg" >> "$LOG_FILE"
        echo "[FAILED] $pkg"
    else
        echo "[INSTALLED] $pkg"
    fi
}

# Main installation loop
for pkg in "${PACKAGES[@]}"; do
    install_pacman_package "$pkg"
done

# Install AUR-only packages
for pkg in "${AUR_PACKAGES[@]}"; do
    install_aur_package "$pkg"
done

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
    fish_path=$(which fish)
    grep -qF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
    sudo usermod -s "$fish_path" "$(logname)"
    echo "[SET] fish as default shell"
fi
