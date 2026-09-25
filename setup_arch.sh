#!/bin/bash
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

set -e

# --- SAFETY GUARDS ---

if [ "$EUID" -eq 0 ]; then
	echo "❌ Error: Do not run this script as root or with sudo."
	echo "The script will invoke sudo when elevated privileges are required."
	exit 1
fi

# --- DRY RUN MODE ---

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
	DRY_RUN=true
	echo "--- !!! DRY RUN MODE ENABLED !!! ---"
	echo "No files will be changed and no commands will be executed."
	sleep 1
fi

# --- HELPERS ---

log_info() {
	if command -v gum >/dev/null 2>&1; then
		gum style --foreground 4 ":: $1"
	else
		echo ":: $1"
	fi
}

log_success() {
	if command -v gum >/dev/null 2>&1; then
		gum style --foreground 2 "✅ $1"
	else
		echo "✅ $1"
	fi
}

log_error() {
	if command -v gum >/dev/null 2>&1; then
		gum style --foreground 1 "❌ $1"
	else
		echo "❌ $1"
	fi
}

run_cmd() {
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would execute: $*"
	else
		"$@"
	fi
}

_isInstalled() {
	local pkg="$1"
	if pacman -Q "$pkg" &>/dev/null; then
		return 0
	fi
	if command -v "$pkg" &>/dev/null; then
		return 0
	fi
	return 1
}

ensure_installed() {
	if ! _isInstalled "$1"; then
		return 1
	fi
	log_success "$2 is already installed."
	return 0
}

_installRepoPackages() {
	local toInstall=()
	for pkg in "$@"; do
		if pacman -Q "$pkg" &>/dev/null; then
			log_success "${pkg} is already installed."
			continue
		fi
		toInstall+=("$pkg")
	done

	if [[ ${#toInstall[@]} -eq 0 ]]; then
		return
	fi

	log_info "Installing official repository packages..."
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would install with pacman: ${toInstall[*]}"
	else
		sudo pacman -S --needed --noconfirm "${toInstall[@]}"
	fi
}

_installAurPackages() {
	local toInstall=()
	for pkg in "$@"; do
		if pacman -Q "$pkg" &>/dev/null; then
			log_success "${pkg} is already installed."
			continue
		fi
		toInstall+=("$pkg")
	done

	if [[ ${#toInstall[@]} -eq 0 ]]; then
		return
	fi

	log_info "Installing AUR packages..."
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would install with paru: ${toInstall[*]}"
	else
		paru -S --needed --noconfirm "${toInstall[@]}"
	fi
}

# --- INITIALIZATION ---

clear

if command -v gum >/dev/null 2>&1; then
	gum style --border normal --margin "1" --padding "1" --foreground 212 \
		"Arch Hyprland Dotfiles Installer"
else
	echo -e '\033[0;32m'
	cat <<"EOF"
 ___            _        _ _           
|_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 | || '_ \/ __| __/ _` | | |/ _ \ '__|
 | || | | \__ \ || (_| | | |  __/ |   
|___|_| |_|___/\__\__,_|_|_|\___|_|   
                                      
EOF
	echo "for Arch Hyprland Dotfiles"
	echo -e '\033[0m'
fi

log_info "Initializing Setup Script..."

if [ "$DRY_RUN" = true ]; then
	log_info "Dry run mode - skipping confirmation prompt."
else
	if command -v gum >/dev/null 2>&1; then
		if ! gum confirm "Do you want to start the installation?"; then
			log_info "Installation canceled."
			exit 0
		fi
	else
		while true; do
			read -rp "DO YOU WANT TO START THE INSTALLATION NOW? (Yy/Nn): " yn
			case $yn in
			[Yy]*)
				break
				;;
			[Nn]*)
				log_info "Installation canceled."
				exit 0
				;;
			*) echo "Please answer yes or no." ;;
			esac
		done
	fi
fi

log_info "Installation started."

# --- SUDO KEEP-ALIVE ---

if [ "$DRY_RUN" = false ]; then
	sudo -v
	while true; do
		sudo -n true
		sleep 60
		kill -0 "$$" || exit
	done 2>/dev/null &
fi

# --- SYSTEM PREPARATION ---

log_info "Updating system and databases..."
run_cmd sudo pacman -Syu --noconfirm

# Activate parallel downloads in pacman.conf
if grep -q "^#ParallelDownloads = 5" /etc/pacman.conf; then
	log_info "Enabling parallel downloads in pacman.conf..."
	run_cmd sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
else
	log_success "Parallel downloads already configured."
fi

# Activate Color in pacman.conf
if grep -Fxq "#Color" /etc/pacman.conf || grep -Fxq "# Color" /etc/pacman.conf; then
	log_info "Enabling color in pacman.conf..."
	run_cmd sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
	run_cmd sudo sed -i 's/^# Color/Color/' /etc/pacman.conf
else
	log_success "Color already configured in pacman.conf."
fi

# --- CORE BASE DEPENDENCIES ---

dependencies=(
	"base-devel"
	"git"
	"gnome-keyring"
	"networkmanager"
	"openssh"
)

log_info "Installing base build and connectivity dependencies..."
_installRepoPackages "${dependencies[@]}"

# --- MISE ---

ensure_installed "mise" "Mise" || {
	log_info "Installing Mise..."
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would install mise via curl"
	else
		curl https://mise.run | sh
	fi
}

log_info "Activating Mise and installing core developer toolset..."
if [ "$DRY_RUN" = false ]; then
	eval "$("$HOME"/.local/bin/mise activate bash)"
	mise use -g --yes age@latest bun@latest chezmoi@latest github-cli@latest gum@latest node@latest rust@latest
	if _isInstalled "rustup"; then
		log_info "Configuring Rust toolchain..."
		rustup default stable
		rustup update
	fi
else
	echo "[DRY-RUN] Would activate mise and install: age, bun, chezmoi, github-cli, gum, node, rust"
fi

# --- PARU (AUR HELPER) ---

ensure_installed "paru" "Paru" || {
	log_info "Installing Paru..."
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would clone and build paru from AUR"
	else
		git clone https://aur.archlinux.org/paru.git /tmp/paru
		(cd /tmp/paru && makepkg -si --noconfirm)
		rm -rf /tmp/paru
		log_success "Paru installed successfully."
	fi
}

# --- SSH DAEMON ---

log_info "Starting SSH daemon..."
run_cmd sudo systemctl enable sshd
run_cmd sudo systemctl start sshd
if [ "$DRY_RUN" = false ]; then
	nmcli -f IP4.ADDRESS device show
fi
log_success "SSH daemon started."

# --- IDENTITY & SSH KEYGEN ---

if command -v gum >/dev/null 2>&1; then
	gum style --border normal --margin "1" --padding "1" --foreground 212 "User Identity & SSH"
fi

default_name="jonathancrangle"
default_email="94425204+joncrangle@users.noreply.github.com"

if [ "$DRY_RUN" = true ]; then
	GIT_NAME="$default_name"
	GIT_EMAIL="$default_email"
else
	GIT_NAME=$(gum input --header "Enter your Git User Name" --value "$default_name")
	GIT_EMAIL=$(gum input --header "Enter your Git Email" --value "$default_email")
fi

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
	if [ "$DRY_RUN" = true ] || gum confirm "Generate a new SSH key for GitHub?"; then
		if [ "$DRY_RUN" = true ]; then
			echo "[DRY-RUN] Would generate SSH key for $GIT_EMAIL"
		else
			log_info "Generating ED25519 key for $GIT_EMAIL..."
			ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519 -N ""

			touch ~/.ssh/config
			if ! grep -q "IdentityFile ~/.ssh/id_ed25519" ~/.ssh/config 2>/dev/null; then
				printf "Host *\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/id_ed25519\n" >>~/.ssh/config
			fi
			log_success "SSH identity configured."
		fi
	fi
else
	log_success "SSH key already exists at ~/.ssh/id_ed25519."
fi

# --- GIT & AUTH ---

log_info "Updating Git Global Config..."
run_cmd git config --global user.name "$GIT_NAME"
run_cmd git config --global user.email "$GIT_EMAIL"

if ! gh auth status >/dev/null 2>&1; then
	log_info "GitHub CLI authentication required."
	[ "$DRY_RUN" = false ] && gh auth login --web
else
	log_success "GitHub CLI already authenticated."
fi

# --- DOTFILES ---

log_info "Checking for Chezmoi age key..."
if [ "$DRY_RUN" = false ]; then
	log_info "Local IP Address(es) for SCP:"
	ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1

	while [ ! -f "$HOME/.config/key.txt" ]; do
		if command -v gum >/dev/null 2>&1; then
			gum style --foreground 1 "CRITICAL: ~/.config/key.txt is missing."
			gum confirm "Have you placed the key.txt file?" || exit 1
		else
			read -rp "Please put key.txt in ~/.config/. Press Enter to continue"
		fi
	done
else
	echo "[DRY-RUN] Would wait for ~/.config/key.txt"
fi

log_info "Applying dotfiles via Chezmoi..."
run_cmd chezmoi init --apply git@github.com:joncrangle/.dotfiles.git

# --- LOCAL FONTS ---

log_info "Installing custom local fonts..."
if [ "$DRY_RUN" = false ]; then
	fonts_directory="$HOME/.config/fonts"
	user_fonts_folder="/usr/share/fonts/tx-02"

	if [ -d "$fonts_directory" ]; then
		sudo mkdir -p "$user_fonts_folder"
		for font_file in "$fonts_directory"/*.ttf "$fonts_directory"/*.otf; do
			if [ -f "$font_file" ]; then
				font_name=$(basename "$font_file")
				destination_path="$user_fonts_folder/$font_name"
				if [ ! -f "$destination_path" ]; then
					sudo cp "$font_file" "$destination_path"
					echo "Installed font - $font_name"
				fi
			fi
		done
		sudo fc-cache -f
		log_success "Local fonts installed."
	fi
else
	echo "[DRY-RUN] Would sync fonts from ~/.config/fonts to /usr/share/fonts/tx-02"
fi

# --- SYSTEM PACKAGES ---

repo_packages=(
	"audacity"
	"blueman"
	"bluez"
	"brightnessctl"
	"btop"
	"cava"
	"cliphist"
	"cmus"
	"dart-sass"
	"exiv2"
	"ffmpeg"
	"gimp"
	"gpu-screen-recorder"
	"greetd"
	"grim"
	"gvfs"
	"handbrake"
	"hypridle"
	"hyprland"
	"hyprpicker"
	"imagemagick"
	"imv"
	"iwd"
	"krita"
	"libgtop"
	"libreoffice-fresh"
	"luarocks"
	"mariadb-libs"
	"mpv"
	"noctalia"
	"noto-fonts"
	"noto-fonts-emoji"
	"obsidian"
	"otf-font-awesome"
	"pamixer"
	"papirus-icon-theme"
	"pavucontrol"
	"pipewire-pulse"
	"playerctl"
	"podman"
	"podman-compose"
	"polkit-gnome"
	"poppler"
	"power-profiles-daemon"
	"python"
	"qalculate-gtk"
	"qt6-multimedia-ffmpeg"
	"qt6-wayland"
	"slurp"
	"smartmontools"
	"system-config-printer"
	"thunar"
	"thunar-archive-plugin"
	"tldr"
	"ttc-iosevka-aile"
	"ttf-jetbrains-mono-nerd"
	"tumbler"
	"udiskie"
	"unarchiver"
	"upower"
	"usbutils"
	"viu"
	"vlc"
	"wezterm-nightly-bin"
	"wf-recorder"
	"wget"
	"wireplumber"
	"wl-clipboard"
	"xdg-desktop-portal-gtk"
	"xdg-desktop-portal-hyprland"
	"xdg-terminal-exec"
	"xdg-utils"
	"zathura"
	"zip"
	"zsh"
)

aur_packages=(
	"bibata-cursor-theme-bin"
	"catppuccin-cursors-mocha"
	"catppuccin-gtk-theme-mocha"
	"dropbox"
	"grimblast-git"
	"helium-browser-bin"
	"localsend-bin"
	"maplemono-ttf"
	"noctalia"
	"nwg-look"
	"plexamp-appimage"
	"spotify"
	"topgrade-bin"
	"vicinae-bin"
	"wezterm-nightly-bin"
	"zen-browser-bin"
	"zoom"
	"zsh-antidote"
)

_installRepoPackages "${repo_packages[@]}"
_installAurPackages "${aur_packages[@]}"

# --- APP CONFIGURATION ---

log_info "Configuring themes and UI..."
if _isInstalled "bat"; then
	run_cmd bat cache --build
fi

if _isInstalled "nwg-look"; then
	run_cmd nwg-look -a
fi

THEME_DIR=$(find /usr/share/themes -maxdepth 1 -type d -iname "*catppuccin-mocha*" 2>/dev/null | head -n 1)
if [[ -n "$THEME_DIR" && -d "$THEME_DIR" ]]; then
	log_info "Linking GTK4 assets from $THEME_DIR..."
	if [ "$DRY_RUN" = false ]; then
		mkdir -p "${HOME}/.config/gtk-4.0"
		[ -d "${THEME_DIR}/gtk-4.0/assets" ] && ln -sf "${THEME_DIR}/gtk-4.0/assets" "${HOME}/.config/gtk-4.0/assets"
		[ -f "${THEME_DIR}/gtk-4.0/gtk.css" ] && ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"
		[ -f "${THEME_DIR}/gtk-4.0/gtk-dark.css" ] && ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
	else
		echo "[DRY-RUN] Would link GTK4 files from $THEME_DIR"
	fi
fi

# Yazi plugins
if _isInstalled "ya"; then
	log_info "Updating Yazi plugins..."
	run_cmd ya pkg install
	run_cmd ya pkg upgrade
fi

# Mise global tool installation from Chezmoi dotfiles
if _isInstalled "mise"; then
	log_info "Installing Mise packages managed by dotfiles..."
	run_cmd mise install --yes
fi

# --- ZEN BROWSER STYLES ---

zen_config="$HOME/.config/zen-styles"
if [ -d "$zen_config" ]; then
	log_info "Applying Zen Browser user styles..."
	if [ "$DRY_RUN" = false ]; then
		zen_path="$HOME/.zen"
		if [ -f "$zen_path/profiles.ini" ]; then
			profile_rel=$(awk -F= '/^\[Profile/ {p=1} /^Default=1/ {d=1} /^Path=/ && p && d {print $2; exit}' "$zen_path/profiles.ini")
			profile_rel=${profile_rel:-$(grep -E "^Path=" "$zen_path/profiles.ini" | head -n 1 | cut -d= -f2)}

			if [ "$profile_rel" != "" ]; then
				full_profile="$zen_path/$profile_rel"
				log_info "Syncing chrome styling to profile: $profile_rel"
				mkdir -p "$full_profile/chrome"
				cp -rfv "$zen_config/"* "$full_profile/chrome/"
				log_success "Zen styles applied."
			fi
		fi
	else
		echo "[DRY-RUN] Would copy Zen styles from ~/.config/zen-styles"
	fi
fi

# --- JUJUTSU ---

if _isInstalled "jj"; then
	log_info "Setting Jujutsu identity..."
	run_cmd jj config set --user user.name "$GIT_NAME"
	run_cmd jj config set --user user.email "$GIT_EMAIL"
fi

# --- CONFLICT CLEANUP ---

if _isInstalled "ttf-ms-fonts"; then
	log_info "Detected ttf-ms-fonts conflict."
	if [ "$DRY_RUN" = true ] || gum confirm "Do you want to uninstall conflicting ttf-ms-fonts?"; then
		run_cmd sudo pacman --noconfirm -R ttf-ms-fonts
	fi
fi

# --- SYSTEM SERVICES ---

log_info "Configuring system services..."

# greetd autologin
if _isInstalled "greetd"; then
	log_info "Configuring greetd..."
	if [ "$DRY_RUN" = false ]; then
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
	else
		echo "[DRY-RUN] Would configure /etc/greetd/config.toml"
	fi
	log_success "greetd configured."
fi

# power-profiles-daemon
if systemctl is-enabled --quiet power-profiles-daemon.service 2>/dev/null; then
	log_success "power-profiles-daemon already enabled."
else
	run_cmd sudo systemctl unmask power-profiles-daemon.service
	run_cmd sudo systemctl enable --now power-profiles-daemon.service
	log_success "power-profiles-daemon enabled."
fi

# NetworkManager + iwd backend
if _isInstalled "networkmanager"; then
	log_info "Setting iwd as NetworkManager Wi-Fi backend..."
	if [ "$DRY_RUN" = false ]; then
		sudo mkdir -p /etc/NetworkManager/conf.d
		echo -e "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf >/dev/null
	else
		echo "[DRY-RUN] Would configure NetworkManager iwd backend"
	fi
	run_cmd sudo systemctl enable --now iwd.service
	run_cmd sudo systemctl enable --now NetworkManager.service
	log_success "Networking services configured."
fi

# Bluetooth
if _isInstalled "bluez"; then
	run_cmd sudo systemctl enable --now bluetooth.service
	log_success "Bluetooth service enabled."
fi

# Default shell
if _isInstalled "zsh"; then
	if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
		log_info "Setting default shell to zsh..."
		run_cmd chsh -s /bin/zsh "$USER"
	fi
fi

# --- EXIT ---

if [ "$DRY_RUN" = true ]; then
	log_success "Dry run complete. No changes were executed."
else
	echo ""
	log_success "Setup complete!"

	if command -v gum >/dev/null 2>&1; then
		if gum confirm "Do you want to reboot your system now?"; then
			gum spin --spinner dot --title "Rebooting..." -- sleep 2
			systemctl reboot
		else
			log_info "Reboot skipped."
		fi
	else
		read -rp "Do you want to reboot your system now? (y/N): " reb
		case $reb in
		[Yy]*) systemctl reboot ;;
		*) log_info "Reboot skipped." ;;
		esac
	fi
fi
