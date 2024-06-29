#!/bin/bash
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
    pacman -Q --color never "${package}" &> /dev/null
    if [ $? -eq 0 ]; then
        echo 0  # '0' means 'true' in Bash
    else
        echo 1  # '1' means 'false' in Bash
    fi
}

_isInstalledParu() {
    package="$1"
    paru -Q --color never "${package}" &> /dev/null
    if [ $? -eq 0 ]; then
        echo 0  # '0' means 'true' in Bash
    else
        echo 1  # '1' means 'false' in Bash
    fi
}

# Install required packages
_installPackagesPacman() {
    toInstall=();
    for pkg; do
        if [[ $(_isInstalledPacman "${pkg}") -eq 0 ]]; then
            echo "${pkg} is already installed.";
            continue;
        fi;
        toInstall+=("${pkg}");
    done;
    if [[ "${toInstall[@]}" == "" ]] ; then
        # echo "All pacman packages are already installed.";
        return;
    fi;
    printf "Package not installed:\n%s\n" "${toInstall[@]}";
    sudo pacman --noconfirm -S "${toInstall[@]}";
}

_installPackagesParu() {
    toInstall=();
    for pkg; do
        if [[ $(_isInstalledParu "${pkg}") -eq 0 ]]; then
            echo ":: ${pkg} is already installed.";
            continue;
        fi;
        toInstall+=("${pkg}");
    done;

    if [[ "${toInstall[@]}" == "" ]] ; then
        # echo "All packages are already installed.";
        return;
    fi;

    # printf "AUR packags not installed:\n%s\n" "${toInstall[@]}";
    paru --noconfirm --needed --noprovides -S "${toInstall[@]}";
}

_commandExists() {
    package="$1";
    if ! type $package > /dev/null 2>&1; then
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
RED='\033[0;31m'   #'0;31' is Red
GREEN='\033[0;32m'   #'0;32' is Green
YELLOW='\033[1;32m'   #'1;32' is Yellow
BLUE='\033[0;34m'   #'0;34' is Blue
NONE='\033[0m'      # NO COLOR

# Header
echo -e "${GREEN}"
cat <<"EOF"
 ___           _        _ _           
|_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 | || '_ \/ __| __/ _` | | |/ _ \ '__|
 | || | | \__ \ || (_| | | |  __/ |   
|___|_| |_|___/\__\__,_|_|_|\___|_|   
                                      
EOF
echo "for Arch Hyprland Dotfiles"
echo
echo -e "${NONE}"
while true; do
    read -p "DO YOU WANT TO START THE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]* )
            echo ":: Installation started."
            echo
        break;;
        [Nn]* ) 
            echo ":: Installation canceled."
            exit;
        break;;
        * ) echo ":: Please answer yes or no.";;
    esac
done

# Synchronizing package databases
sudo pacman -Sy
echo

# Install required packages
echo ":: Checking that required packages are installed..."
_installPackagesPacman "${dependencies[@]}";
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
    new_line=$(echo $line | sed 's/^#//')
    sudo sed -i "s/$line/$new_line/g" /etc/pacman.conf
fi

# Activate Color in pacman.conf
if grep -Fxq "#Color" /etc/pacman.conf
then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    echo ":: Color activated in pacman.conf"
else
    echo ":: Color is already activated in pacman.conf"
fi
if grep -Fxq "# Color" /etc/pacman.conf
then
    sudo sed -i 's/^# Color/Color/' /etc/pacman.conf
    echo ":: Color activated in pacman.conf"
fi
echo

# Install paru
if sudo pacman -Qs paru > /dev/null ; then
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
    echo "Host *\n AddKeysToAgent yes\n IdentityFile ~/.ssh/id_ed25519" | tee ~/.ssh/config
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
    "bat"
    "bemoji"
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
    "cliphist"
    "cmus"
    "docker"
    "docker-compose"
    "dropbox"
    "eza" 
    "fastfetch"
    "fd"
    "feh"
    "ffmpegthumbnailer"
    "fuzzel-git"
    "fzf"
    "gcc"
    "gimp"
    "git-delta"
    "glow"
    "gnu-free-fonts"
    "go"
    "grim"
    "gum"
    "handbrake"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
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
    "network-manager-applet"
    "networkmanager"
    "networkmanager-dmenu-git"
    "nodejs"
    "noto-fonts" 
    "noto-fonts-emoji"
    "npm"
    "nwg-look"
    "obsidian"
    "otf-font-awesome" 
    "papirus-icon-theme"
    "pavucontrol" 
    "playerctl"
    "pnpm"
    "polkit-kde-agent"
    "poppler"
    "power-profiles-daemon"
    "pulseaudio"
    "python"
    "python-pip"
    "qalculate-gtk"
    "qt5ct"
    "qt6ct"
    "qt5-wayland"
    "qt6-wayland"
    "ripgrep"
    "sddm-git"
    "sddm-theme-catppuccin"
    "slurp"
    "smartmontools"
    "spotifyd"
    "spotify-player"
    "starship"
    "swappy"
    "swaync"
    "thefuck"
    "thunar"
    "thunar-archive-plugin"
    "tldr"
    "otf-font-awesome"
    "ttf-cascadia-code-nerd"
    "ttf-droid"
    "ttf-fira-code"
    "ttf-fira-sans" 
    "ttf-font-awesome"
    "ttf-iosevka"
    "ttf-iosevka-term"
    "ttf-jetbrains-mono-nerd"
    "ttf-liberation"
    "ttf-maple"
    "ttf-meslo-nerd-font-powerlevel10k"
    "tumbler"
    "udiskie"
    "unarchiver"
    "unrar"
    "unzip"
    "vlc" 
    "waybar"
    "wezterm-git"
    "wf-recorder"
    "wget"
    "wireplumber"
    "wl-clipboard"
    "wlogout"
    "wpa_supplicant"
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
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
);

echo ":: Installing packages..."
_installPackagesParu "${packages[@]}";
paru -S ffmpeg-libfdk_aac
bat cache --build
sudo mkdir -p /etc/sddm.conf.d
sudo ln -s ~/.config/sddm/sddm.conf /etc/sddm.conf.d/sddm.conf
sudo sed -i 's|^Background="backgrounds/wall.jpg"|Background="~\/.config\/hypr\/wallpapers\/cat-sound.png"|g' /usr/share/sddm/themes/catppuccin-mocha/theme.conf
echo

# Check for ttf-ms-fonts
if [[ $(_isInstalledPacman "ttf-ms-fonts") == 0 ]]; then
    echo "The script has detected ttf-ms-fonts. This can cause conflicts with icons in Waybar."
    if gum confirm "Do you want to uninstall ttf-ms-fonts?" ;then
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
if [[ $(systemctl list-units --all -t service --full --no-legend "power-profiles-daemon.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "power-profiles-daemon.service" ]];then
    echo ":: power-profiles-daemon.service already running."
else
    sudo systemctl unmask power-profiles-daemon.service
    sudo systemctl enable power-profiles-daemon.service
    echo ":: power-profiles-daemon.service activated successfully."    
fi

# Check for running NetworkManager.service
if [[ $(systemctl list-units --all -t service --full --no-legend "NetworkManager.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "NetworkManager.service" ]];then
    echo ":: NetworkManager.service already running."
else
    sudo systemctl enable NetworkManager.service
    sudo systemctl start NetworkManager.service
    echo ":: NetworkManager.service activated successfully."    
fi

# Check for running bluetooth.service
if [[ $(systemctl list-units --all -t service --full --no-legend "bluetooth.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "bluetooth.service" ]];then
    echo ":: bluetooth.service already running."
else
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    echo ":: bluetooth.service activated successfully."    
fi

# Check for running spotifyd.service
if [[ $(systemctl list-units --all -t service --full --no-legend "spotifyd.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "spotifyd.service" ]];then
    echo ":: spotifyd.service already running."
else
    systemctl --user enable spotifyd.service --now
    echo ":: spotifyd.service activated successfully."    
fi

xdg-user-dirs-update
chsh -s /bin/zsh
echo

echo ":: Setup complete."
echo "A reboot of your system is recommended."
echo
if gum confirm "Do you want to reboot your system now?" ;then
    gum spin --spinner dot --title "Rebooting now..." -- sleep 3
    systemctl reboot
elif [ $? -eq 130 ]; then
    exit 130
else
    echo ":: Reboot skipped"
fi

echo ""
sleep 3
