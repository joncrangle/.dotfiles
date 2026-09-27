#!/usr/bin/env bash
#  NOTE:
#           .:'
#       __ :'__
#    .'`__`-'__``.
#   :__________.-'
#   :_________:
#    :_________`-;
#     `.__.-.__.'

set -euo pipefail

# --- CONFIGURATION ---

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "--- DRY RUN MODE ---"
  echo "No changes will be made."
fi

DEFAULT_NAME="jonathancrangle"
DEFAULT_EMAIL="94425204+joncrangle@users.noreply.github.com"
AGE_KEY="$HOME/.config/key.txt"

# --- HELPERS ---

log_info() {
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground 4 ":: $1"
  else
    printf ':: %s\n' "$1"
  fi
}

log_success() {
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground 2 "✓ $1"
  else
    printf '✓ %s\n' "$1"
  fi
}

log_warning() {
  printf 'WARNING: %s\n' "$1" >&2
}

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[DRY-RUN] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_installed() {
  if command -v "$1" >/dev/null 2>&1; then
    log_success "$2 is installed."
    return 0
  fi
  return 1
}

confirm() {
  local message="$1"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would ask: $message"
    return 1
  fi

  gum confirm "$message"
}

section() {
  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border normal \
      --margin "1" \
      --padding "1" \
      --foreground 212 "$1"
  else
    printf '\n--- %s ---\n' "$1"
  fi
}

# --- INITIALIZATION ---

if [[ "$DRY_RUN" == false ]]; then
  clear
fi

log_info "Initializing macOS setup..."

# Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  log_info "Xcode Command Line Tools not found."

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would install Xcode Command Line Tools"
  else
    xcode-select --install
    log_warning "Complete the Xcode installation, then rerun this script."
    exit 0
  fi
else
  log_success "Xcode Command Line Tools detected."
fi

# --- HOMEBREW ---

if ! ensure_installed brew "Homebrew"; then
  log_info "Installing Homebrew..."

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would install Homebrew"
  else
    NONINTERACTIVE=1 /bin/bash -c "$(
      curl -fsSL \
        https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    )"
  fi
fi

# Make Homebrew available in this shell.
if [[ "$DRY_RUN" == false ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

run_cmd touch "$HOME/.hushlogin"

# --- MISE ---

if ! ensure_installed mise "Mise"; then
  log_info "Installing Mise..."

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would install Mise"
  else
    curl -fsSL https://mise.run | sh
  fi
fi

log_info "Activating Mise..."

if [[ "$DRY_RUN" == false ]]; then
  MISE_BIN="$(command -v mise || true)"
  MISE_BIN="${MISE_BIN:-$HOME/.local/bin/mise}"

  if [[ ! -x "$MISE_BIN" ]]; then
    log_warning "Mise executable not found."
    exit 1
  fi

  eval "$("$MISE_BIN" activate bash)"

  log_info "Installing core toolset..."

  mise use -g \
    age@latest \
    chezmoi@latest \
    github-cli@latest \
    gum@latest \
    rust@latest \
    bun@latest

  log_success "Core toolset installed."
else
  echo "[DRY-RUN] Would activate Mise"
  echo "[DRY-RUN] Would install age, chezmoi, gh, gum, rust and bun"
fi

# --- IDENTITY & SSH ---

section "User Identity & SSH"

if [[ "$DRY_RUN" == true ]]; then
  GIT_NAME="$DEFAULT_NAME"
  GIT_EMAIL="$DEFAULT_EMAIL"
else
  GIT_NAME="$(
    gum input \
      --header "Enter your Git User Name" \
      --value "$DEFAULT_NAME"
  )"

  GIT_EMAIL="$(
    gum input \
      --header "Enter your Git Email" \
      --value "$DEFAULT_EMAIL"
  )"
fi

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_CONFIG="$HOME/.ssh/config"

if [[ ! -f "$SSH_KEY" ]]; then
  if confirm "Generate a new SSH key for GitHub?"; then
    log_info "Generating ED25519 SSH key..."

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    ssh-keygen \
      -t ed25519 \
      -C "$GIT_EMAIL" \
      -f "$SSH_KEY" \
      -N ""

    # Preserve existing SSH configuration.
    if [[ ! -f "$SSH_CONFIG" ]]; then
      cat >"$SSH_CONFIG" <<'EOF'
Host github.com
  HostName github.com
  User git
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF

      chmod 600 "$SSH_CONFIG"
    else
      log_info "Existing SSH config preserved."
    fi

    # Use the existing agent when available.
    if ! ssh-add -l >/dev/null 2>&1; then
      eval "$(ssh-agent -s)"
    fi

    ssh-add --apple-use-keychain "$SSH_KEY"

    log_success "SSH identity configured."
  fi
else
  log_success "Existing SSH key detected."
fi

# --- GIT & GITHUB AUTH ---

section "Git & GitHub"

log_info "Updating global Git configuration..."

run_cmd git config --global user.name "$GIT_NAME"
run_cmd git config --global user.email "$GIT_EMAIL"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would check GitHub authentication"
elif ! gh auth status >/dev/null 2>&1; then
  log_info "GitHub CLI authentication required."
  gh auth login --web --git-protocol ssh
else
  log_success "GitHub CLI already authenticated."
fi

# --- DOTFILES ---

section "Dotfiles"

log_info "Checking for Chezmoi age key..."

if [[ "$DRY_RUN" == false ]]; then
  while [[ ! -f "$AGE_KEY" ]]; do
    gum style --foreground 1 \
      "CRITICAL: $AGE_KEY is missing."

    gum confirm "Have you placed the key.txt file?" || exit 1
  done
else
  echo "[DRY-RUN] Would check for $AGE_KEY"
fi

log_info "Applying dotfiles via Chezmoi..."

run_cmd chezmoi init --apply \
  git@github.com:joncrangle/.dotfiles.git

# Refresh Mise after Chezmoi has applied configuration.
if [[ "$DRY_RUN" == false ]]; then
  eval "$("$MISE_BIN" activate bash)"
fi

# --- FONTS ---

section "Fonts"

FONT_SOURCE="$HOME/.config/fonts"
FONT_DEST="$HOME/Library/Fonts"

log_info "Syncing fonts..."

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would copy fonts from $FONT_SOURCE"
elif [[ -d "$FONT_SOURCE" ]]; then
  mkdir -p "$FONT_DEST"

  find "$FONT_SOURCE" -type f \
    \( -name "*.ttf" -o -name "*.otf" \) \
    -exec cp -v {} "$FONT_DEST/" \;

  log_success "Fonts synchronized."
else
  log_warning "Font directory not found. Skipping."
fi

# --- PACKAGES ---

section "Packages"

log_info "Starting Homebrew Bundle..."

BREWFILE="$HOME/.config/homebrew/Brewfile"

if [[ "$DRY_RUN" == true || -f "$BREWFILE" ]]; then
  run_cmd brew bundle --file="$BREWFILE"
else
  log_warning "Brewfile not found. Skipping."
fi

log_info "Running Mise Install..."

run_cmd mise install --yes

# --- JUJUTSU ---

section "Jujutsu"

log_info "Writing Jujutsu configuration..."

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would configure Jujutsu"
elif command -v jj >/dev/null 2>&1; then
  JJ_CONFIG_PATH="$(jj config path --user)"

  mkdir -p "$(dirname "$JJ_CONFIG_PATH")"

  cat >"$JJ_CONFIG_PATH" <<EOF
[user]
name = "$GIT_NAME"
email = "$GIT_EMAIL"

[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor \\$left \\$right \\$output"]

[ui.diff]
format = "git"
EOF

  log_success "Jujutsu configured."
else
  log_warning "Jujutsu is not installed. Skipping."
fi

# --- MACOS UI ---

section "macOS UI"

log_info "Configuring Dock autohide..."

run_cmd osascript -e \
  'tell application "System Events" to set autohide of dock preferences to true'

# --- SKETCHYBAR ---

section "Sketchybar"

log_info "Building Sketchybar components..."

SBAR_REPO="https://github.com/FelixKratz/SbarLua.git"
SBAR_DIR="$(mktemp -d)/SbarLua"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would clone and install SbarLua"
else
  git clone "$SBAR_REPO" "$SBAR_DIR"

  (
    cd "$SBAR_DIR"
    make install
  )

  rm -rf "$(dirname "$SBAR_DIR")"

  log_success "SbarLua installed."
fi

# --- ZEN BROWSER STYLES ---

section "Zen Browser"

ZEN_STYLES="$HOME/.config/zen-styles"
ZEN_ROOT="$HOME/Library/Application Support/Zen"
ZEN_PROFILES="$ZEN_ROOT/profiles.ini"

if [[ -d "$ZEN_STYLES" ]]; then
  log_info "Checking Zen Browser profile..."

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would synchronize Zen Browser styles"
  elif [[ -f "$ZEN_PROFILES" ]]; then

    # Find the default profile's path.
    REL_PATH="$(
      awk -F= '
        /^\[Profile/ {
          if (profile && is_default && path != "") {
            print path
            exit
          }
          profile = 1
          is_default = 0
          path = ""
        }
        /^Path=/ && profile {
          path = $2
        }
        /^Default=1/ && profile {
          is_default = 1
        }
        END {
          if (profile && is_default && path != "") {
            print path
          }
        }
      ' "$ZEN_PROFILES" | head -n 1
    )"

    # Fall back to the first profile.
    if [[ -z "$REL_PATH" ]]; then
      REL_PATH="$(
        grep -m 1 '^Path=' "$ZEN_PROFILES" |
          cut -d= -f2- || true
      )"
    fi

    if [[ -n "$REL_PATH" ]]; then
      if [[ "$REL_PATH" = /* ]]; then
        ZEN_PROFILE_DIR="$REL_PATH"
      else
        ZEN_PROFILE_DIR="$ZEN_ROOT/$REL_PATH"
      fi

      ZEN_CHROME="$ZEN_PROFILE_DIR/chrome"

      log_info "Applying CSS to $ZEN_CHROME"

      mkdir -p "$ZEN_CHROME"

      rsync -av --delete \
        "$ZEN_STYLES/" \
        "$ZEN_CHROME/"

      log_success "Zen Browser styles applied."
    else
      log_warning "No Zen Browser profile found."
    fi
  else
    log_warning "Zen Browser profiles.ini not found."
  fi
fi

# --- AGENT CONFIGURATION ---

section "Agent Configuration"

if command -v herdr >/dev/null 2>&1; then
  log_info "Installing Herdr integrations..."

  run_cmd herdr integration install antigravity-cli
  run_cmd herdr integration install opencode
  run_cmd herdr integration install pi
elif [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would install Herdr integrations if available"
else
  log_warning "Herdr is not installed. Skipping integrations."
fi

# --- MATT POCOCK SKILLS ---

section "Agent Skills"

log_info "Installing Matt Pocock skills globally..."

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would install all Matt Pocock skills to all supported agents"
else
  if ! command -v bunx >/dev/null 2>&1; then
    log_warning "Bun is not available."
    exit 1
  fi

  bunx --bun skills@latest add mattpocock/skills \
    --global \
    --agent '*' \
    --skill '*' \
    --yes

  log_success "Matt Pocock skills installed."
fi

# --- MACOS PREFERENCES ---

section "macOS Preferences"

if confirm "Run macOS system defaults script?"; then
  MACOS_SCRIPT="$HOME/.config/.macos"

  if [[ -f "$MACOS_SCRIPT" ]]; then
    run_cmd sh "$MACOS_SCRIPT"
  else
    log_warning "macOS defaults script not found."
  fi
fi

# --- EXIT ---

if [[ "$DRY_RUN" == true ]]; then
  log_success "Dry run complete. No changes were made."
else
  if command -v gum >/dev/null 2>&1; then
    gum style \
      --border double \
      --margin "1" \
      --padding "1" \
      --foreground 2 \
      "Setup Complete! Please restart your Mac."
  else
    log_success "Setup complete! Please restart your Mac."
  fi
fi
