#!/bin/sh
clear
sudo -v
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

# ------------------------------------------------------
# Utility functions
# ------------------------------------------------------
_isInstalledPacman() {
    package="$1"
    pacman -Q --color never "$package" &>/dev/null
    if [ $? -eq 0 ]; then
        echo 0 # '0' means 'true' in Bash
    else
        echo 1 # '1' means 'false' in Bash
    fi
}

_isInstalledParu() {
    package="$1"
    paru -Q --color never "$package" &>/dev/null
    if [ $? -eq 0 ]; then
        echo 0 # '0' means 'true' in Bash
    else
        echo 1 # '1' means 'false' in Bash
    fi
}

# Install required packages
_installPackagesPacman() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalledPacman "$pkg") -eq 0 ]]; then
            echo "${pkg} is already installed."
            continue
        fi
        toInstall+=("$pkg")
    done
    if [[ "${toInstall[@]}" == "" ]]; then
        # echo "All pacman packages are already installed.";
        return
    fi
    printf "Package not installed:\n%s\n" "${toInstall[@]}"
    sudo pacman --noconfirm -S "${toInstall[@]}"
}

_installPackagesParu() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalledParu "$pkg") -eq 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        toInstall+=("$pkg")
    done

    if [[ "${toInstall[@]}" == "" ]]; then
        # echo "All packages are already installed.";
        return
    fi

    # printf "AUR packags not installed:\n%s\n" "${toInstall[@]}";
    paru --noconfirm --needed --noprovides -S "${toInstall[@]}"
}

_commandExists() {
    package="$1"
    if ! type "$package" >/dev/null 2>&1; then
        echo ":: ERROR: $package doesn't exists. Please install it with paru -S $2"
    else
        echo ":: OK: $package command found."
    fi
}

# ------------------------------------------------------
# Main
# ------------------------------------------------------
dependencies=(
    "age"
    "base-devel"
    "chezmoi"
    "github-cli"
    "gum"
    "openssh"
    "rustup"
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
_installPackagesPacman "${dependencies[@]}"
echo

# Install Rust
echo ":: Installing Rust..."
rustup default stable
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
if sudo pacman -Qs paru >/dev/null; then
    echo ":: paru is already installed!"
else
    echo ":: paru is not installed. Starting the installation!"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
    echo ":: paru has been installed successfully."
    paru
fi
echo

# Generate SSH key
if gum confirm "Do you want to generate a new SSH key for GitHub?"; then
    echo ":: Generating a new SSH key for GitHub..."
    ssh-keygen -t ed25519 -C "94425204+joncrangle@users.noreply.github.com" -f ~/.ssh/id_ed25519
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
git config --global user.name "jonathancrangle"
git config --global user.email "94405204+joncrangle@users.noreply.github.com"

echo ":: Please run 'gh auth login --web' to authenticate with GitHub."
read -p "Press Enter to continue after you have completed the authentication."

# Migrate dotfiles using chezmoi
echo ":: Migrating dotfiles..."
read -p ":: Please put key.txt in ~/.config/. Press Enter to continue"
chezmoi init --apply git@github.com:joncrangle/.dotfiles.git

packages=(
    "audacity"
    "aylurs-gtk-shell-git"
    "bat"
    "bibata-cursor-theme-bin"
    "blueman"
    "bluez"
    "bluez-utils"
    "brave-bin"
    "brightnessctl"
    "btop"
    "bun-bin"
    "catppuccin-cursors-mocha"
    "catppuccin-gtk-theme-mocha"
    "cava"
    "cliphist"
    "cmus"
    "docker"
    "docker-compose"
    "dropbox"
    "exiv2"
    "eza"
    "fastfetch"
    "fd"
    "feh"
    "ffmpeg"
    "ffmpegthumbnailer"
    "fzf"
    "gcc"
    "gimp"
    "git-delta"
    "glow"
    "gnome-bluetooth-3.0"
    "gnome-control-center"
    "gnu-free-fonts"
    "go"
    "grim"
    "gum"
    "handbrake"
    "hypridle-git"
    "hyprland-git"
    "hyprlock-git"
    "hyprpicker-git"
    "imagemagick"
    "imv"
    "jq"
    "krita"
    "lazydocker"
    "lazygit"
    "libreoffice"
    "lua"
    "luajit"
    "luarocks"
    "make"
    "mpv"
    "neovim"
    "networkmanager"
    "nodejs"
    "noto-fonts"
    "noto-fonts-emoji"
    "npm"
    "nwg-look"
    "obsidian"
    "otf-font-awesome"
    "pamixer"
    "papirus-icon-theme"
    "pavucontrol"
    "pipewire-audio"
    "pipewire-pulse"
    "playerctl"
    "plexamp-appimage"
    "pnpm"
    "polkit-gnome"
    "poppler"
    "power-profiles-daemon"
    "python"
    "python-uv"
    "qalculate-gtk"
    "qt6-wayland"
    "ripgrep"
    "sddm-git"
    "sddm-theme-catppuccin"
    "slurp"
    "smartmontools"
    "spotify"
    "starship"
    "swww-git"
    "system-config-printer"
    "thefuck"
    "thunar"
    "thunar-archive-plugin"
    "tldr"
    "ttf-cascadia-code-nerd"
    "ttf-droid"
    "ttf-fira-code"
    "ttf-fira-sans"
    "ttf-font-awesome"
    "ttf-iosevka"
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
    "vlc"
    "wezterm-git"
    "wf-recorder"
    "wget"
    "wireplumber"
    "wl-clipboard"
    "wpa_supplicant"
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
    "xdg-terminal-exec"
    "xdg-user-dirs"
    "xdg-utils"
    "yazi-git"
    "yt-dlp"
    "yq"
    "zathura"
    "zig"
    "zip"
    "zoom"
    "zoxide"
    "zsh"
    "zsh-antidote"
)

echo ":: Installing packages..."
_installPackagesParu "${packages[@]}"
echo

echo ":: Setting up theme..."
if [[ $(_isInstalledParu "bat") -eq 0 ]]; then
    bat cache --build
fi

if [[ -f ~/.config/hypr/wallpapers/catppuccin-city.jpg ]]; then
    cp ~/.config/hypr/wallpapers/catppuccin-city.jpg ~/.config/background
    chmod a+r ~/.config/background
fi

if [[ $(_isInstalledParu "nwg-look") -eq 0 ]]; then
    nwg-look -a
fi

THEME_DIR="/usr/share/themes/catppuccin-mocha-mauve-standard+default"
if [[ -d "${THEME_DIR}" ]]; then
    mkdir -p "${HOME}/.config/gtk-4.0"
    ln -sf "${THEME_DIR}/gtk-4.0/assets" "${HOME}/.config/gtk-4.0/assets"
    ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"
    ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
fi

if [[ $(_isInstalledParu "sddm") -eq 0 ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo ln -s ~/.config/sddm/sddm.conf /etc/sddm.conf.d/sddm.conf
    sudo rm /usr/share/sddm/themes/catppuccin-mocha/backgrounds/background
    sudo ln -s ~/.config/background /usr/share/sddm/themes/catppuccin-mocha/backgrounds/background
    sudo sed -i 's|^CustomBackground="false"|CustomBackground="true"|g' /usr/share/sddm/themes/catppuccin-mocha/theme.conf
    sudo sed -i 's|^LoginBackground="false"|LoginBackground="true"|g' /usr/share/sddm/themes/catppuccin-mocha/theme.conf
    sudo sed -i 's|^wall.jpg"|background"|g' /usr/share/sddm/themes/catppuccin-mocha/theme.conf
    sudo mkdir -p /var/lib/sddm/.config/hypr
    sudo tee /var/lib/sddm/.config/hypr/hyprland.conf >/dev/null <<EOF
monitor=,preferred,auto,1,mirror,DP-1
exec-once = hyprctl setcursor catppuccin-mocha-dark-cursors 28
exec-once = hypridle
input {
    kb_layout = us
    kb_variant =
    kb_options =
}
animations {
    enabled = false
}
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    focus_on_activate = true
}
EOF
    sudo tee /var/lib/sddm/.config/hypr/hypridle.conf >/dev/null <<EOF
general {
    after_sleep_cmd = hyprctl dispatch dpms on
}
# screen brightness
listener {
    timeout = 150 # 2.5 minutes
    on-timeout = brightnessctl -s set 0
    on-resume = brightnessctl -r
}
# dpms
listener {
    timeout = 600 # 10 minutes
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
# Suspend
#listener {
#    timeout = 1800 # 30 minutes
#    on-timeout = systemctl suspend
#}
EOF
fi
echo

# Install yazi plugins
if [[ $(_isInstalledParu "yazi-git") == 0 ]]; then
    echo ":: Installing yazi plugins..."
    ya pack -i
    ya pack -u
fi

# Check for ttf-ms-fonts
if [[ $(_isInstalledParu "ttf-ms-fonts") == 0 ]]; then
    echo "The script has detected ttf-ms-fonts. This can cause conflicts with icons in Waybar."
    if gum confirm "Do you want to uninstall ttf-ms-fonts?"; then
        sudo pacman --noconfirm -R ttf-ms-fonts
    fi
fi

# Enable services
echo ":: Enabling services..."

# Check for running sddm.service
if [ -f /etc/systemd/system/display-manager.service ]; then
    echo ":: Display Manager is already enabled."
else
    sudo systemctl enable sddm.service
    echo ":: sddm.service enabled successfully."
fi

# Check for running power-profiles-daemon.service
if [[ $(systemctl list-units --all -t service --full --no-legend "power-profiles-daemon.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "power-profiles-daemon.service" ]]; then
    echo ":: power-profiles-daemon.service already running."
else
    sudo systemctl unmask power-profiles-daemon.service
    sudo systemctl enable power-profiles-daemon.service
    echo ":: power-profiles-daemon.service activated successfully."
fi

# Check for running NetworkManager.service
if [[ $(systemctl list-units --all -t service --full --no-legend "NetworkManager.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "NetworkManager.service" ]]; then
    echo ":: NetworkManager.service already running."
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

# Check for running docker.service
if [[ $(systemctl list-units --all -t service --full --no-legend "docker.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "docker.service" ]]; then
    echo ":: docker.service already running."
else
    systemctl --user enable docker.service
    systemctl --user start docker.service
    echo ":: docker.service activated successfully."
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

if [[ $(_isInstalledParu "xdg-user-dirs") -eq 0 ]]; then
    xdg-user-dirs-update
fi
if [[ $(_isInstalledParu "zsh") -eq 0 ]]; then
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
