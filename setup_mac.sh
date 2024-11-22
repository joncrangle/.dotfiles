#/bin/sh
#  NOTE:
#           .:'
#       __ :'__
#    .'`__`-'__``.
#   :__________.-'
#   :_________:
#    :_________`-;
#     `.__.-.__.'

# Install Xcode cli tools
if ! xcode-select -p &>/dev/null; then
	echo "Xcode command line tools not found. Installing..."
	xcode-select --install
else
	echo "Xcode command line tools are already installed."
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
	echo "Installing Homebrew, chezmoi, and Git..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew install age
	brew install chezmoi
	brew install gh
	brew install git
	brew install zsh
	chsh -s "$(which zsh)"
fi

# Ask if user wants to generate Github SSH key
read -p "Do you want to generate a new SSH key for GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Generating a new SSH key for GitHub..."
	ssh-keygen -t ed25519 -C "94425204+joncrangle@users.noreply.github.com" -f ~/.ssh/id_ed25519
	eval "$(ssh-agent -s)"
	touch ~/.ssh/config
	echo "Host *\n AddKeysToAgent yes\n IdentityFile ~/.ssh/id_ed25519" | tee ~/.ssh/config >/dev/null
	ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

echo "Configuring Git..."
git config --global user.name "jonathancrangle"
git config --global user.email "94405204+joncrangle@users.noreply.github.com"

read -p "Please run 'gh auth login' to authenticate with GitHub. Press Enter to continue after you have completed the authentication."

# Migrate dotfiles using chezmoi
echo "Migrating dotfiles..."
read -p "Please put key.txt in ~/.config/. Press Enter to continue"
chezmoi init --apply git@github.com:joncrangle/.dotfiles.git

# Install fonts
echo "Installing fonts..."
fonts_directory="$HOME/.config/fonts"
user_fonts_folder="$HOME/Library/Fonts"
if [ ! -d "$user_fonts_folder" ]; then
	mkdir -p "$user_fonts_folder"
fi
for font_file in "$fonts_directory"/*.ttf "$fonts_directory"/*.otf; do
	if [ -f "$font_file" ]; then
		font_name=$(basename "$font_file")
		destination_path="$user_fonts_folder/$font_name"
		if [ ! -f "$destination_path" ]; then
			cp "$font_file" "$destination_path"
			echo "Installed font - $font_name"
		else
			echo "Font $font_name is already installed. Skipping copy."
		fi
	fi
done
echo "Fonts installed successfully."

# Install Brewfile from .config/homebrew
echo "Installing Brewfile..."
brew bundle --file="$HOME"/.config/homebrew/Brewfile
rustup update
rustup component add rust-analyzer
cargo install cargo-update
cargo install cargo-cache
cargo install --locked bacon
ya pack -i
ya pack -u
asdf plugin add nodejs
asdf install nodejs latest
asdf global nodejs latest
asdf local nodejs latest

mkdir -p $HOME/Documents/Code
# Start yabai, skhd, sketchybar and borders
osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true'
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
(git clone git@github.com:kvndrsslr/sketchybar-app-font.git $HOME/Documents/Code && pnpm install && pnpm run build:install)
git clone git@github.com:joncrangle/sketchybar-system-stats.git $HOME/.config/sketchybar
cargo build --manifest-path $HOME/.config/sketchybar/stats_provider/Cargo.toml --release
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 "$(which yabai)" | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
brew services start sketchybar
skhd --start-service
yabai --start-service

# Update Mac system preferences
read -p "Do you want to update Mac system preferences? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	chmod +x ".config/.macos"
	sh ".config/.macos"
fi

echo "Setup completed successfully."
echo "Please restart your computer for changes to take effect."
echo ""
sleep 3
