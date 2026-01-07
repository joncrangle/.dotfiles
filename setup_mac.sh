#!/bin/sh
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
  brew install git
  brew install zsh
  chsh -s "$(which zsh)"
fi

# Install Mise
if ! command -v mise &>/dev/null; then
  echo "Installing Mise..."
  curl https://mise.run | sh
else
  echo "Mise is already installed."
fi

eval "$("$HOME"/.local/bin/mise activate bash)"
echo "Installing dependencies..."
mise use -g age@latest chezmoi@latest github-cli@latest gum@latest rust@latest

# --- IDENTITY PROMPT ---
default_name="jonathancrangle"
default_email="94425204+joncrangle@users.noreply.github.com"
echo ":: Configuring User Identity..."
GIT_NAME=$(gum input --header "Git User Name" --value "$default_name")
GIT_EMAIL=$(gum input --header "Git Email" --value "$default_email")
if gum confirm "Generate a new SSH key for GitHub?"; then
  echo "Generating a new SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519
  eval "$(ssh-agent -s)"
  touch ~/.ssh/config
  echo -e "Host *\n AddKeysToAgent yes\n IdentityFile ~/.ssh/id_ed25519" | tee ~/.ssh/config >/dev/null
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

echo "Configuring Git..."
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
echo "Migrating dotfiles..."
read -p "Please put 'key.txt' in ~/.config/. Press Enter to continue"
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

echo "Installing Apps and Tools..."
mise lock
mise install --yes
brew bundle --file="$HOME"/.config/homebrew/Brewfile
if command -v rustup &>/dev/null; then
  rustup default stable
  rustup update
fi
luarocks install busted
ya pkg install
ya pkg upgrade
jj config set --user user.name "$GIT_NAME"
jj config set --user user.email "$GIT_EMAIL"
echo -e '\n[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor $left $right $output"]

[ui.diff]
format = "git"' | tee -a "$(jj config path --user)" >/dev/null

mkdir -p "$HOME"/Documents/Code
# Configure SbarLua and custom Sketchybar setup
osascript -e 'tell application "System Events" to set autohide menu bar of dock preferences to true'
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
(git clone git@github.com:kvndrsslr/sketchybar-app-font.git "$HOME"/Documents/Code && bun install && bun run build:install)
git clone git@github.com:joncrangle/sketchybar-system-stats.git "$HOME"/.config/sketchybar
just "$HOME"/.config/sketchybar/build
brew services start sketchybar
brew services start svim

zen_config="$HOME/.config/zen-styles"
if [ -d "$zen_config" ]; then
  zen_path="$HOME/Library/Application Support/Zen"
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
