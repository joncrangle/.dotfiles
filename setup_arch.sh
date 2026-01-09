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

# Executes command unless in dry-run mode
run_cmd() {
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would execute: $*"
	else
		"$@"
	fi
}

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

# Check for command and provide status
ensure_installed() {
	if ! _isInstalled "$1"; then
		return 1
	fi
	log_success "$2 is already installed."
	return 0
}

# Install packages - uses paru if available, otherwise pacman
# Installs one-by-one to handle failures gracefully
_installPackages() {
	local toInstall=()
	for pkg in "$@"; do
		if _isInstalled "$pkg"; then
			log_success "${pkg} is already installed."
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
		log_info "Installing $pkg..."
		package="${pkg#aur/}"
		if [ "$DRY_RUN" = true ]; then
			echo "[DRY-RUN] Would install: $package"
		else
			if ! "$installer" -S --noconfirm --needed "$package"; then
				log_error "Failed to install $pkg. Continuing with next package..."
			fi
		fi
	done
}

# --- INITIALIZATION ---

clear

if command -v gum >/dev/null 2>&1; then
	gum style --border normal --margin "1" --padding "1" --foreground 212 \
		"Arch Hyprland Dotfiles Installer"
else
	echo -e '\033[0;32m'
	cat <<"EOF"
 ___           _        _ _           
|_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 | || '_ \/ __| __/ _` | | |/ _ \ '__|
 | || | | \__ \ || (_| | | |  __/ |   
|___|_| |_|___/\__\__,_|_|_|\___|_|   
                                      
EOF
	echo "for Arch Hyprland Dotfiles"
	echo -e '\033[0m'
fi

log_info "Initializing Setup Script..."

# Confirmation prompt
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

log_info "Synchronizing package databases..."
run_cmd sudo pacman -Sy

# Activate parallel downloads in pacman.conf
if grep -q "^#ParallelDownloads = 5" /etc/pacman.conf; then
	log_info "Enabling parallel downloads in pacman.conf..."
	run_cmd sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
else
	log_success "Parallel downloads already enabled."
fi

# Activate Color in pacman.conf
if grep -Fxq "#Color" /etc/pacman.conf || grep -Fxq "# Color" /etc/pacman.conf; then
	log_info "Enabling color in pacman.conf..."
	run_cmd sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
	run_cmd sudo sed -i 's/^# Color/Color/' /etc/pacman.conf
else
	log_success "Color already enabled in pacman.conf."
fi

# --- DEPENDENCIES ---

dependencies=(
	"base-devel"
	"git"
	"gnome-keyring"
	"networkmanager"
	"openssh"
)

log_info "Installing base dependencies..."
_installPackages "${dependencies[@]}"

# --- MISE ---

ensure_installed "mise" "Mise" || {
	log_info "Installing Mise..."
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would install mise via curl"
	else
		curl https://mise.run | sh
	fi
}

# Activate Mise and Install Tools
log_info "Activating Mise and installing core toolset..."
if [ "$DRY_RUN" = false ]; then
	eval "$("$HOME"/.local/bin/mise activate bash)"
	mise use -g --yes age@latest bun@latest chezmoi@latest github-cli@latest gum@latest node@latest rust@latest
	if _isInstalled "rustup"; then
		log_info "Configuring Rust toolchain..."
		rustup default stable
		rustup update
	else
		log_error "Rustup shim not found. Mise install might have failed."
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
		if ! _isInstalled "git"; then
			log_error "git is not installed. Cannot install paru."
			exit 1
		fi
		git clone https://aur.archlinux.org/paru.git /tmp/paru
		cd /tmp/paru || exit
		makepkg -si --noconfirm
		cd ..
		rm -rf /tmp/paru
		log_success "Paru installed successfully."
		paru
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

# --- IDENTITY & SSH ---

if command -v gum >/dev/null 2>&1; then
	gum style --border normal --margin "1" --padding "1" --foreground 212 "User Identity & SSH"
fi

default_name="jonathancrangle"
default_email="94425204+joncrangle@users.noreply.github.com"

# In Dry Run, we skip the interactive input
if [ "$DRY_RUN" = true ]; then
	GIT_NAME="$default_name"
	GIT_EMAIL="$default_email"
else
	GIT_NAME=$(gum input --header "Enter your Git User Name" --value "$default_name")
	GIT_EMAIL=$(gum input --header "Enter your Git Email" --value "$default_email")
fi

if [ "$DRY_RUN" = true ] || gum confirm "Generate a new SSH key for GitHub?"; then
	if [ "$DRY_RUN" = true ]; then
		echo "[DRY-RUN] Would generate SSH key for $GIT_EMAIL"
	else
		log_info "Generating ED25519 key for $GIT_EMAIL..."
		ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519 -N ""

		log_info "Configuring SSH Agent..."
		eval "$(ssh-agent -s)"
		touch ~/.ssh/config
		printf "Host *\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/id_ed25519\n" >~/.ssh/config
		ssh-add ~/.ssh/id_ed25519
		log_success "SSH identity configured."
	fi
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

# --- FONTS ---

log_info "Installing fonts..."
if [ "$DRY_RUN" = false ]; then
	fonts_directory="$HOME/.config/fonts"
	user_fonts_folder="/usr/share/fonts/tx-02"

	sudo mkdir -p "$user_fonts_folder"

	for font_file in "$fonts_directory"/*.ttf "$fonts_directory"/*.otf; do
		if [ -f "$font_file" ]; then
			font_name=$(basename "$font_file")
			destination_path="$user_fonts_folder/$font_name"
			if [ ! -f "$destination_path" ]; then
				sudo cp "$font_file" "$destination_path"
				echo "Installed font - $font_name"
			else
				echo "Font $font_name is already installed. Skipping."
			fi
		fi
	done

	sudo fc-cache -f -v
else
	echo "[DRY-RUN] Would install fonts from ~/.config/fonts to /usr/share/fonts/tx-02"
fi
log_success "Fonts installed successfully."

# --- PACKAGES ---

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

log_info "Installing packages..."
_installPackages "${packages[@]}"

log_info "Running Mise Install..."
run_cmd mise install --yes

# --- APP CONFIGURATION ---

log_info "Setting up theme..."
if _isInstalled "bat"; then
	run_cmd bat cache --build
fi

if _isInstalled "nwg-look"; then
	run_cmd nwg-look -a
fi

THEME_DIR="/usr/share/themes/catppuccin-mocha-mauve-standard+default"
if [[ -d "$THEME_DIR" ]]; then
	log_info "Linking GTK4 theme..."
	if [ "$DRY_RUN" = false ]; then
		mkdir -p "${HOME}/.config/gtk-4.0"
		ln -sf "${THEME_DIR}/gtk-4.0/assets" "${HOME}/.config/gtk-4.0/assets"
		ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"
		ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
	else
		echo "[DRY-RUN] Would link GTK4 theme from $THEME_DIR"
	fi
fi

# Yazi plugins
if _isInstalled "ya"; then
	log_info "Installing yazi plugins..."
	run_cmd ya pkg install
	run_cmd ya pkg upgrade
fi

# Mise runtimes
if _isInstalled "mise"; then
	log_info "Locking and installing mise tools..."
	run_cmd mise lock
	run_cmd mise install --yes
fi

# --- ZEN BROWSER STYLES ---

zen_config="$HOME/.config/zen-styles"
if [ -d "$zen_config" ]; then
	log_info "Checking Zen Browser Profile..."
	if [ "$DRY_RUN" = false ]; then
		zen_path="$HOME/.zen"
		if [ -f "$zen_path/profiles.ini" ]; then
			profile_rel=$(awk -F= '/^\[Profile/ {p=1} /^Default=1/ {d=1} /^Path=/ && p && d {print $2; exit}' "$zen_path/profiles.ini")
			profile_rel=${profile_rel:-$(grep -E "^Path=" "$zen_path/profiles.ini" | head -n 1 | cut -d= -f2)}

			if [ "$profile_rel" != "" ]; then
				full_profile="$zen_path/$profile_rel"
				log_info "Applying CSS to: $profile_rel"
				mkdir -p "$full_profile/chrome"
				cp -rfv "$zen_config/"* "$full_profile/chrome/"
				log_success "Zen Styles applied successfully."
			fi
		else
			log_info "Zen profiles.ini not found. Skipping."
		fi
	else
		echo "[DRY-RUN] Would sync Zen styles via cp."
	fi
fi

# --- JUJUTSU ---

log_info "Writing Jujutsu (jj) configuration..."
if _isInstalled "jj"; then
	if [ "$DRY_RUN" = false ]; then
		jj config set --user user.name "$GIT_NAME"
		jj config set --user user.email "$GIT_EMAIL"
		JJ_CONFIG_PATH=$(jj config path --user)
		mkdir -p "$(dirname "$JJ_CONFIG_PATH")"
		cat <<EOF >>"$JJ_CONFIG_PATH"

[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor \$left \$right \$output"]

[ui.diff]
format = "git"
EOF
	else
		echo "[DRY-RUN] Would configure jj for $GIT_NAME"
	fi
fi

# --- CLEANUP ---

# Check for ttf-ms-fonts
if _isInstalled "ttf-ms-fonts"; then
	log_info "Detected ttf-ms-fonts. This can cause icon conflicts."
	if [ "$DRY_RUN" = true ] || gum confirm "Do you want to uninstall ttf-ms-fonts?"; then
		run_cmd sudo pacman --noconfirm -R ttf-ms-fonts
	fi
fi

# --- SERVICES ---

log_info "Enabling services..."

# greetd autologin
if _isInstalled "greetd"; then
	log_info "Configuring greetd for autologin..."
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
		echo "[DRY-RUN] Would configure greetd autologin"
	fi
	log_success "greetd.service configured."
fi

# power-profiles-daemon
if [[ $(systemctl list-units --all -t service --full --no-legend "power-profiles-daemon.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "power-profiles-daemon.service" ]]; then
	log_success "power-profiles-daemon.service already running."
else
	run_cmd sudo systemctl unmask power-profiles-daemon.service
	run_cmd sudo systemctl enable power-profiles-daemon.service
	log_success "power-profiles-daemon.service activated."
fi

# iwd backend for NetworkManager
if _isInstalled "networkmanager"; then
	log_info "Configuring iwd as NetworkManager backend..."
	if [ "$DRY_RUN" = false ]; then
		sudo mkdir -p /etc/NetworkManager/conf.d
		echo -e "[device]\nwifi.backend=iwd" | sudo tee /etc/NetworkManager/conf.d/iwd.conf >/dev/null
	else
		echo "[DRY-RUN] Would configure iwd backend"
	fi
	log_success "NetworkManager backend configured."
fi

# iwd service
if ! systemctl is-active --quiet iwd; then
	log_info "Starting iwd service..."
	run_cmd sudo systemctl enable iwd.service
	run_cmd sudo systemctl start iwd.service
fi

# NetworkManager
if [[ $(systemctl list-units --all -t service --full --no-legend "NetworkManager.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "NetworkManager.service" ]]; then
	run_cmd sudo systemctl restart NetworkManager.service
	log_success "NetworkManager.service restarted."
else
	run_cmd sudo systemctl enable NetworkManager.service
	run_cmd sudo systemctl start NetworkManager.service
	log_success "NetworkManager.service activated."
fi

# Bluetooth
if [[ $(systemctl list-units --all -t service --full --no-legend "bluetooth.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "bluetooth.service" ]]; then
	log_success "bluetooth.service already running."
else
	run_cmd sudo systemctl enable bluetooth.service
	run_cmd sudo systemctl start bluetooth.service
	log_success "bluetooth.service activated."
fi

# SSH agent user service
if [[ -f ~/.ssh/id_ed25519 ]]; then
	log_info "Configuring SSH agent user service..."
	if [ "$DRY_RUN" = false ]; then
		mkdir -p ~/.config/systemd/user
		cat >~/.config/systemd/user/ssh-agent.service <<EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
Environment=DISPLAY=:0
ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
		systemctl enable --user ssh-agent.service
		eval "$(ssh-agent -s)"
		ssh-add ~/.ssh/id_ed25519
	else
		echo "[DRY-RUN] Would configure ssh-agent user service"
	fi
	log_success "SSH agent configured."
fi

# Set default shell to zsh
if _isInstalled "zsh"; then
	log_info "Setting default shell to zsh..."
	run_cmd chsh -s /bin/zsh
fi

# --- EXIT ---

if [ "$DRY_RUN" = true ]; then
	log_success "Dry run complete. No changes were made."
else
	if command -v gum >/dev/null 2>&1; then
		gum style --border double --margin "1" --padding "1" --foreground 2 "Setup Complete! Please restart your system."
	else
		echo ""
		log_success "Setup complete."
		echo "A reboot of your system is recommended."
	fi

	if gum confirm "Do you want to reboot your system now?"; then
		gum spin --spinner dot --title "Rebooting now..." -- sleep 3
		systemctl reboot
	else
		log_info "Reboot skipped."
	fi
fi
