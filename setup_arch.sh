#!/bin/bash
# script inspiration source: [Stephan Raabe dotfiles](https://gitlab.com/stephan-raabe/dotfiles)
#  NOTE:
#                                  ▄
#                                 ▄█▄
#                                ▄███▄
#                               ▄█████▄
#                              ▄███████▄
#                             ▄ ▀▀██████▄
#                            ▄██▄▄ ▀█████▄
#                           ▄█████████████▄
#                          ▄███████████████▄
#                         ▄█████████████████▄
#                        ▄███████████████████▄
#                       ▄█████████▀▀▀▀████████▄
#                      ▄████████▀      ▀███████▄
#                     ▄█████████        ████▀▀██▄
#                    ▄██████████        █████▄▄▄
#                   ▄██████████▀        ▀█████████▄
#                  ▄██████▀▀▀              ▀▀██████▄
#                 ▄███▀▀                       ▀▀███▄
#                ▄▀▀                               ▀▀▄

clear
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# ------------------------------------------------------
# Utility functions
# ------------------------------------------------------

# Check if a package is installed (Supports Pacman, Paru/AUR, and Mise)
_isInstalled() {
    local pkg="${1#aur/}"
    # 1. Check System Database (Official Repos & AUR)
    if pacman -Q "$pkg" &>/dev/null; then
        return 0
    fi

    # 2. Check User PATH (Mise & Manual Binaries)
    if command -v "$pkg" &>/dev/null; then
        return 0
    fi

    return 1
}

# Install packages - uses paru if available, otherwise pacman
# Installs one-by-one to handle failures gracefully
_installPackages() {
    local toInstall=()
    for pkg in "$@"; do
        if _isInstalled "$pkg"; then
            echo "${pkg} is already installed."
            continue
        fi
        toInstall+=("$pkg")
    done

    if [[ ${#toInstall[@]} -eq 0 ]]; then
        return
    fi

    local installer
    if _isInstalled "paru"; then
        installer="paru"
    else
        installer="sudo pacman"
    fi

    for pkg in "${toInstall[@]}"; do
        echo ":: Installing $pkg..."
        package="${pkg#aur/}"
        if ! "$installer" -S --noconfirm --needed "$package"; then
            echo ":: ERROR: Failed to install $pkg. Continuing with next package..."
        fi
    done
}

# ------------------------------------------------------
# Main
# ------------------------------------------------------
dependencies=(
    "base-devel"
    "git"
    "gnome-keyring"
    "networkmanager"
    "openssh"
)

# Some colors
RED='\033[0;31m'    #'0;31' is Red
GREEN='\033[0;32m'  #'0;32' is Green
YELLOW='\033[1;32m' #'1;32' is Yellow
BLUE='\033[0;34m'   #'0;34' is Blue
NONE='\033[0m'      # NO COLOR

# Header
echo -e "$GREEN"
cat <<"EOF"
 ___           _        _ _           
|_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 | || '_ \/ __| __/ _` | | |/ _ \ '__|
 | || | | \__ \ || (_| | | |  __/ |   
|___|_| |_|___/\__\__,_|_|_|\___|_|   
                                      
EOF
echo "for Arch Hyprland Dotfiles"
echo
echo -e "$NONE"
while true; do
    read -p "DO YOU WANT TO START THE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
    [Yy]*)
        echo ":: Installation started."
        echo
        break
        ;;
    [Nn]*)
        echo ":: Installation canceled."
        exit
        break
        ;;
    *) echo ":: Please answer yes or no." ;;
    esac
done

# Synchronizing package databases
sudo pacman -Sy
echo

#y Install required packages
echo ":: Checking that required packages are installed..."
curl https://mise.run | sh
_installPackages "${dependencies[@]}"
if _isInstalled "mise"; then
    echo ":: Bootstrapping tools via Mise..."
    eval "$(mise activate bash)"
    mise use -g --yes age@latest bun@latest chezmoi@latest github-cli@latest gum@latest node@latest rust@latest
    if _isInstalled "rustup"; then
        echo ":: Configuring Rust toolchain..."
        rustup default stable
        rustup update
    else
        echo ":: ERROR: Rustup shim not found. Mise install might have failed."
    fi
else
    echo ":: ERROR: Mise was not found in system packages. Cannot bootstrap tools."
    exit 1
fi
echo

echo ":: Starting ssh daemon..."
sudo systemctl enable sshd
sudo systemctl start sshd
nmcli -f IP4.ADDRESS device show
echo ":: ssh daemon started."

gum spin --spinner dot --title "Starting the installation now..." -- sleep 3

# Activate parallel downloads in pacman.conf
line=$(grep "ParallelDownloads = 5" /etc/pacman.conf)
if [[ $line == \#* ]]; then
    echo ":: Modifying pacman.conf to enable parallel downloads."
    new_line=$(echo "$line" | sed 's/^#//')
    sudo sed -i "s/$line/$new_line/g" /etc/pacman.conf
fi

# Activate Color in pacman.conf
if grep -Fxq "#Color" /etc/pacman.conf; then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    echo ":: Color activated in pacman.conf"
else
    echo ":: Color is already activated in pacman.conf"
fi
if grep -Fxq "# Color" /etc/pacman.conf; then
    sudo sed -i 's/^# Color/Color/' /etc/pacman.conf
    echo ":: Color activated in pacman.conf"
fi
echo

# Install paru

if _isInstalled "paru"; then
    echo ":: paru is already installed!"
else
    echo ":: paru is not installed. Starting the installation!"
    if ! _isInstalled "git"; then
        echo ":: Error: git is not installed. Cannot install paru."
        exit 1
    fi
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit
    makepkg -si
    cd ..
    rm -rf paru
    echo ":: paru has been installed successfully."
    paru
fi
echo

# --- IDENTITY PROMPT ---
default_name="jonathancrangle"
default_email="94425204+joncrangle@users.noreply.github.com"
GIT_NAME=$(gum input --header "Git User Name" --value "$default_name")
GIT_EMAIL=$(gum input --header "Git Email" --value "$default_email")
if gum confirm "Do you want to generate a new SSH key for GitHub?"; then
    echo ":: Generating a new SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519
    eval "$(ssh-agent -s)"
    touch ~/.ssh/config
    echo "Host *\n AddKeysToAgent yes\n IdentityFile ~/.ssh/id_ed25519" | tee ~/.ssh/config >/dev/null
    ssh-add ~/.ssh/id_ed25519
elif [ $? -eq 130 ]; then
    exit
else
    echo ":: Skipping SSH key generation."
fi

echo ":: Configuring Git..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# GitHub Auth
echo ":: Checking GitHub Authentication..."
if ! gh auth status &>/dev/null; then
    echo ":: Authenticating with GitHub..."
    gh auth login --web
else
    echo ":: GitHub is already authenticated."
fi

# Migrate dotfiles using chezmoi
echo ":: Migrating dotfiles..."
echo ":: Local IP Address(es) for SCP:"
ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1
read -p ":: Please put key.txt in ~/.config/. Press Enter to continue"
chezmoi init --apply git@github.com:joncrangle/.dotfiles.git

# Install fonts
echo ":: Installing fonts..."
fonts_directory="$HOME/.config/fonts"
user_fonts_folder="/usr/share/fonts/tx-02"

if [ ! -d "$user_fonts_folder" ]; then
    sudo mkdir -p "$user_fonts_folder"
fi

for font_file in "$fonts_directory"/*.ttf "$fonts_directory"/*.otf; do
    if [ -f "$font_file" ]; then
        font_name=$(basename "$font_file")
        destination_path="$user_fonts_folder/$font_name"
        if [ ! -f "$destination_path" ]; then
            sudo cp "$font_file" "$destination_path"
            echo "Installed font - $font_name"
        else
            echo "Font $font_name is already installed. Skipping copy."
        fi
    fi
done

sudo fc-cache -f -v
echo "Fonts installed successfully."

# Install packages
packages=(
    "audacity"
    "bibata-cursor-theme-bin"
    "blueman"
    "bluez"
    "bluez-utils"
    "brightnessctl"
    "btop"
    "catppuccin-cursors-mocha"
    "catppuccin-gtk-theme-mocha"
    "cava"
    "cliphist"
    "cmus"
    "crun"
    "cpio"
    "dart-sass"
    "dropbox"
    "exiv2"
    "ffmpeg"
    "ffmpegthumbnailer"
    "gcc"
    "gimp"
    "gpu-screen-recorder"
    "greetd"
    "grim"
    "grimblast-git"
    "gvfs"
    "handbrake"
    "helium-browser-bin"
    "hypridle"
    "hyprland"
    "hyprpicker"
    "imagemagick"
    "imv"
    "iwd"
    "krita"
    "libgtop"
    "libreoffice-fresh"
    "lua"
    "luajit"
    "luarocks"
    "make"
    "maplemono-ttf"
    "mpv"
    "aur/noctalia-shell-git"
    "noto-fonts"
    "noto-fonts-emoji"
    "nwg-look"
    "obsidian"
    "otf-font-awesome"
    "pamixer"
    "papirus-icon-theme"
    "pavucontrol"
    "pipewire-audio"
    "pipewire-pulse"
    "podman"
    "podman-compose"
    "playerctl"
    "plexamp-appimage"
    "polkit-gnome"
    "poppler"
    "power-profiles-daemon"
    "python"
    "qalculate-gtk"
    "qt6-multimedia-ffmpeg"
    "qt6-wayland"
    "quickshell"
    "slurp"
    "smartmontools"
    "aur/spotify"
    "system-config-printer"
    "thunar"
    "thunar-archive-plugin"
    "tldr"
    "topgrade-bin"
    "ttf-cascadia-code-nerd"
    "ttf-droid"
    "ttf-fira-code"
    "ttf-fira-sans"
    "ttf-font-awesome"
    "aur/ttf-iosevka"
    "ttc-iosevka-aile"
    "ttf-iosevka-term"
    "ttf-jetbrains-mono-nerd"
    "ttf-liberation"
    "ttf-maple"
    "ttf-meslo-nerd-font-powerlevel10k"
    "ttf-nerd-fonts-symbols-mono"
    "tumbler"
    "udiskie"
    "unarchiver"
    "unrar"
    "unzip"
    "upower"
    "usbutils"
    "vicinae-bin"
    "viu"
    "vlc"
    "wezterm-git"
    "wf-recorder"
    "wget"
    "wireplumber"
    "wl-clipboard"
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
    "aur/xdg-terminal-exec"
    "xdg-utils"
    "zathura"
    "zen-browser-bin"
    "zip"
    "zoom"
    "zsh"
    "zsh-antidote"
)

echo ":: Installing packages..."
_installPackages "${packages[@]}"
echo

echo

echo ":: Setting up theme..."
if _isInstalled "bat"; then
    bat cache --build
fi

if _isInstalled "nwg-look"; then
    nwg-look -a
fi

THEME_DIR="/usr/share/themes/catppuccin-mocha-mauve-standard+default"
if [[ -d "$THEME_DIR" ]]; then
    mkdir -p "${HOME}/.config/gtk-4.0"
    ln -sf "${THEME_DIR}/gtk-4.0/assets" "${HOME}/.config/gtk-4.0/assets"
    ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"
    ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
fi

# Install yazi plugins
if _isInstalled "ya"; then
    echo ":: Installing yazi plugins..."
    ya pkg install
    ya pkg upgrade
fi

# Install runtimes via mise
if _isInstalled "mise"; then
    echo ":: Installing Apps and Tools..."
    mise lock
    mise install --yes
fi

zen_config="$HOME/.config/zen-styles"
if [ -d "$zen_config" ]; then
    zen_path="$HOME/.zen"

    if [ -f "$zen_path/profiles.ini" ]; then
        echo ":: Configuring Zen Browser..."
        profile_rel=$(grep -E "^Path=" "$zen_path/profiles.ini" | head -n 1 | cut -d= -f2)
        if [ "$profile_rel" != "" ]; then
            full_profile="$zen_path/$profile_rel"
            mkdir -p "$full_profile/chrome"

            cp -r "$zen_config/"* "$full_profile/chrome/"
            echo "   Applied Zen Styles to $full_profile/chrome"
        fi
    else
        echo "   Zen profiles.ini not found. Skipping."
    fi
fi

if _isInstalled "jj"; then
    echo ":: Configuring Jujutsu..."
    jj config set --user user.name "$GIT_NAME"
    jj config set --user user.email "$GIT_EMAIL"
    echo -e '\n[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor $left $right $output"]

[ui.diff]
format = "git"' | tee -a "$(jj config path --user)" >/dev/null
fi

# Check for ttf-ms-fonts
if _isInstalled "ttf-ms-fonts"; then
    echo "The script has detected ttf-ms-fonts. This can cause conflicts with icons."
    if gum confirm "Do you want to uninstall ttf-ms-fonts?"; then
        sudo pacman --noconfirm -R ttf-ms-fonts
    fi
fi

# Enable services
echo ":: Enabling services..."

# Enable greetd autologin and autolock services
if _isInstalled "greetd"; then
    echo ":: configuring greetd for autologin..."
    sudo mkdir -p /etc/greetd
    sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "agreety --cmd start-hyprland"
user = "greeter"

[initial_session]
command = "start-hyprland"
user = "$USER"
EOF
    sudo systemctl enable greetd.service
    echo ":: greetd.service activated successfully."
fi

# Check for running power-profiles-daemon.service
if [[ $(systemctl list-units --all -t service --full --no-legend "power-profiles-daemon.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "power-profiles-daemon.service" ]]; then
    echo ":: power-profiles-daemon.service already running."
else
    sudo systemctl unmask power-profiles-daemon.service
    sudo systemctl enable power-profiles-daemon.service
    echo ":: power-profiles-daemon.service activated successfully."
fi

# Enable iwd backend
if _isInstalled "networkmanager"; then
    echo ":: configuring iwd as NetworkManager backend..."

    sudo mkdir -p /etc/NetworkManager/conf.d
    echo -e "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf >/dev/null

    echo ":: NetworkManager backend configured successfully."
fi

# Ensure iwd is actually running (Required for the backend to work)
if ! systemctl is-active --quiet iwd; then
    echo ":: Starting iwd service (required for backend)..."
    sudo systemctl enable iwd.service
    sudo systemctl start iwd.service
fi

# Restart NetworkManager to apply changes
if [[ $(systemctl list-units --all -t service --full --no-legend "NetworkManager.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "NetworkManager.service" ]]; then
    sudo systemctl restart NetworkManager.service
    echo ":: NetworkManager.service restarted."
else
    sudo systemctl enable NetworkManager.service
    sudo systemctl start NetworkManager.service
    echo ":: NetworkManager.service activated successfully."
fi

# Check for running bluetooth.service
if [[ $(systemctl list-units --all -t service --full --no-legend "bluetooth.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "bluetooth.service" ]]; then
    echo ":: bluetooth.service already running."
else
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    echo ":: bluetooth.service activated successfully."
fi

# Add ssh-key to ssh-agent
if [[ -f ~/.ssh/id_ed25519 ]]; then
    sudo tee ~/.config/systemd/user/ssh-agent.service >/dev/null <<EOF

[Unit]
Description=SSH key agent
 
[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
# DISPLAY required for ssh-askpass to work
Environment=DISPLAY=:0
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK
 
[Install]
WantedBy=default.target
EOF
    systemctl enable --user ssh-agent.service
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
fi

if _isInstalled "zsh"; then
    chsh -s /bin/zsh
fi
echo

echo ":: Setup complete."
echo "A reboot of your system is recommended."
echo
if gum confirm "Do you want to reboot your system now?"; then
    gum spin --spinner dot --title "Rebooting now..." -- sleep 3
    systemctl reboot
elif [ $? -eq 130 ]; then
    exit 130
else
    echo ":: Reboot skipped"
fi

echo ""
sleep 3
