#!/bin/bash
#  NOTE:
#           .:'
#       __ :'__
#    .'`__`-'__``.
#   :__________.-'
#   :_________:
#    :_________`-;
#     `.__.-.__.'

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

# Executes command unless in dry-run mode
run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would execute: $*"
  else
    "$@"
  fi
}

# Check for command and provide status
ensure_installed() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 1
  fi
  log_success "$2 is already installed."
  return 0
}

# --- INITIALIZATION ---

clear
log_info "Initializing Setup Script..."

# Xcode Tools
if ! xcode-select -p >/dev/null 2>&1; then
  log_info "Xcode Command Line Tools not found. Installing..."
  run_cmd "xcode-select --install"
else
  log_success "Xcode Command Line Tools detected."
fi

# Homebrew
ensure_installed "brew" "Homebrew" || {
  log_info "Installing Homebrew..."
  run_cmd "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
}

# Mise
ensure_installed "mise" "Mise" || {
  log_info "Installing Mise..."
  run_cmd "curl https://mise.run | sh"
}

# Activate Mise and Install Tools
log_info "Activating Mise and installing core toolset..."
if [ "$DRY_RUN" = false ]; then
  eval "$("$HOME"/.local/bin/mise activate bash)"
  mise use -g age@latest chezmoi@latest github-cli@latest gum@latest rust@latest
fi

# --- IDENTITY & SSH ---

gum style --border normal --margin "1" --padding "1" --foreground 212 "User Identity & SSH"

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

if gum confirm "Generate a new SSH key for GitHub?"; then
  log_info "Generating ED25519 key for $GIT_EMAIL..."
  run_cmd "ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f ~/.ssh/id_ed25519 -N \"\""

  log_info "Configuring SSH Agent..."
  if [ "$DRY_RUN" = false ]; then
    eval "$(ssh-agent -s)"
    printf "Host *\n  AddKeysToAgent yes\n  IdentityFile ~/.ssh/id_ed25519\n" >~/.ssh/config
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  fi
  log_success "SSH identity configured."
fi

# --- GIT & AUTH ---

log_info "Updating Git Global Config..."
run_cmd "git config --global user.name \"$GIT_NAME\""
run_cmd "git config --global user.email \"$GIT_EMAIL\""

if ! gh auth status >/dev/null 2>&1; then
  log_info "GitHub CLI authentication required."
  [ "$DRY_RUN" = false ] && gh auth login --web
else
  log_success "GitHub CLI already authenticated."
fi

# --- DOTFILES ---

log_info "Checking for Chezmoi age key..."
if [ "$DRY_RUN" = false ]; then
  while [ ! -f "$HOME/.config/key.txt" ]; do
    gum style --foreground 1 "CRITICAL: ~/.config/key.txt is missing."
    gum confirm "Have you placed the key.txt file?" || exit 1
  done
fi

log_info "Applying dotfiles via Chezmoi..."
run_cmd "chezmoi init --apply git@github.com:joncrangle/.dotfiles.git"

# --- FONTS ---

log_info "Syncing Fonts to ~/Library/Fonts..."
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$HOME/Library/Fonts"
  find "$HOME/.config/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -v {} "$HOME/Library/Fonts/" \;
else
  echo "[DRY-RUN] Would find and copy fonts from ~/.config/fonts"
fi

# --- PACKAGES ---

log_info "Starting Homebrew Bundle..."
run_cmd "brew bundle --file=\"$HOME\"/.config/homebrew/Brewfile"

log_info "Running Mise Install..."
run_cmd "mise install --yes"

# --- APP CONFIGURATION ---

log_info "Writing Jujutsu (jj) configuration..."
if [ "$DRY_RUN" = false ]; then
  JJ_CONFIG_PATH=$(jj config path --user)
  mkdir -p "$(dirname "$JJ_CONFIG_PATH")"
  cat <<EOF >"$JJ_CONFIG_PATH"
[user]
name = "$GIT_NAME"
email = "$GIT_EMAIL"

[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor \$left \$right \$output"]

[ui.diff]
format = "git"
EOF
fi

log_info "Configuring macOS UI (Dock autohide)..."
run_cmd "osascript -e 'tell application \"System Events\" to set autohide menu bar of dock preferences to true'"

log_info "Building Sketchybar components..."
run_cmd "(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)"

# --- ZEN BROWSER STYLES ---

if [ -d "$HOME/.config/zen-styles" ]; then
  log_info "Checking Zen Browser Profile..."
  if [ "$DRY_RUN" = false ]; then
    zen_root="$HOME/Library/Application Support/Zen"
    if [ -f "$zen_root/profiles.ini" ]; then
      rel_path=$(awk -F= '/^\[Profile/ {p=1; d=0} /^Default=1/ {d=1} /^Path=/ && p && d {print $2; exit}' "$zen_root/profiles.ini")
      rel_path=${rel_path:-$(grep -E "^Path=" "$zen_root/profiles.ini" | head -n 1 | cut -d= -f2)}

      if [ "$rel_path" != "" ]; then
        log_info "Applying CSS to: $rel_path"
        mkdir -p "$zen_root/$rel_path/chrome"
        rsync -av --delete "$HOME/.config/zen-styles/" "$zen_root/$rel_path/chrome/"
      fi
    fi
  else
    echo "[DRY-RUN] Would sync Zen styles via rsync."
  fi
fi

# --- MAC PREFERENCES ---

if gum confirm "Run macOS system defaults script?"; then
  run_cmd "sh \"$HOME/.config/.macos\""
fi

# --- EXIT ---

if [ "$DRY_RUN" = true ]; then
  log_success "Dry run complete. No changes were made."
else
  gum style --border double --margin "1" --padding "1" --foreground 2 "Setup Complete! Please restart your Mac."
fi
