# pim

Personal Arch Linux installation and setup scripts.

## Overview

Three scripts meant to be run in order after booting the Arch ISO:

| Step | Script | Run as | When |
|------|--------|--------|------|
| 1 | `install.sh` | root (live ISO) | During installation |
| 2 | `root.sh` | root (first boot) | After first boot |
| 3 | `packages.sh` | your user | After logging in |

## Usage

### 1. `install.sh` — Base system install

Run from the Arch live ISO — no need to clone the repo. Execute this directly in the live ISO shell:

```bash
bash -c "bash -i <(curl -fsSL https://raw.githubusercontent.com/tymoyato/arch/main/install.sh) <decryption-password>"
```

What it does:
- Initializes and updates the pacman keyring (`pacman-key --init/--populate`, `archlinux-keyring`)
- Fetches `user_configuration.json` and `user_credentials.json` from GitHub
- Runs `archinstall` with the provided credential decryption key

### 2. `root.sh` — Post-install root setup

Run as root after the first boot into your new system.

```bash
bash root.sh
```

What it does:
- Creates a `builduser` account with passwordless sudo (needed to build AUR packages)
- Installs `base-devel` and `git`
- Installs `yay` (AUR helper) as `builduser`
- Sets up AwesomeWM (`exec awesome`) in `.xinitrc`
- Configures `.bash_profile` to auto-start X on TTY1

### 3. `packages.sh` — Package installation

Run as your regular user after logging in.

```bash
bash packages.sh
```

What it does:
- Installs all packages via `pacman` (or `yay` for AUR packages)
- Logs any failures to `failed_packages.log`
- Sets `fish` as the default shell

#### Installed packages

| Category | Packages |
|----------|----------|
| Base tools | `git`, `curl`, `mercurial`, `make`, `binutils`, `gcc`, `bison` |
| Shell | `fish`, `atuin`, `fzf`, `zoxide`, `less`, `bat`, `eza` |
| WM / X | `awesome`, `rofi`, `picom`, `xorg-server`, `xorg-xinit`, `xorg-setxkbmap`, `xorg-xrandr` |
| Terminal | `kitty` |
| Editor | `neovim` |
| Dev tools | `go`, `rbenv`, `ruby-build`, `lazygit`, `lazydocker`, `difftastic`, `ripgrep`, `shellcheck`, `shfmt` |
| Node | `nvm`, `fisher` |
| Fonts | `noto-fonts-emoji`, `nerd-fonts`, `ttf-liberation`, `ttf-dejavu` |
| Audio | `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `pipewire-jack`, `playerctl`, `alsa-utils` |
| Nvidia | `nvidia-dkms`, `linux-headers`, `nvidia-utils`, `nvidia-settings` |
| Clipboard / Screenshot | `xclip`, `flameshot` |
| System | `wmctrl`, `xdotool`, `util-linux`, `zlib`, `libyaml`, `btop`, `unzip`, `openssh` |
| AUR | `brave-browser`, `light`, `bsdmainutils`, `i3lock-fancy` |

## Configuration

- `user_configuration.json` — archinstall config: btrfs layout on `/dev/sda`, French mirrors, Grub bootloader, Pipewire audio, `Europe/Paris` timezone
- `user_credentials.json` — encrypted archinstall credentials (decryption key passed to `install.sh`)

## Files

```
pim/
├── install.sh              # Step 1: run archinstall
├── root.sh                 # Step 2: builduser + yay setup
├── packages.sh             # Step 3: install all packages
├── user_configuration.json # archinstall configuration
├── user_credentials.json   # archinstall credentials (encrypted)
└── failed_packages.log     # populated by packages.sh on failure
```
