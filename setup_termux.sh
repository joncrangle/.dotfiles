#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NONE='\033[0m'

_command_exists() {
  package="$1"
  if ! type "$package" >/dev/null 2>&1; then
    echo -e "$RED"
    echo ":: ERROR: $package doesn't exist. Please install it with pkg install $2"
    echo -e "$NONE"
    return 1
  fi
  return 0
}

_install_package() {
  local arg="$1"
  local binary pkg_name

  if [[ "$arg" == *:* ]]; then
    binary="${arg%%:*}"
    pkg_name="${arg##*:}"
  else
    binary="$arg"
    pkg_name="$arg"
  fi

  if ! command -v "$binary" >/dev/null 2>&1; then
    if ! gum spin --spinner pulse --title "Installing $pkg_name..." -- pkg install -y "$pkg_name"; then
      echo -e "$RED"
      echo "Failed to install $pkg_name. Please check for errors and try again."
      echo -e "$NONE"
      exit 1
    fi
  else
    echo -e "$YELLOW:: $pkg_name is already installed$NONE"
  fi
}

echo -e "$GREEN"
cat <<"EOF"
░▀█▀░█▀▀░█▀▄░█▄█░█░█░█░█
░░█░░█▀▀░█▀▄░█░█░█░█░▄▀▄
░░▀░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀
EOF
echo
echo -e "$NONE"

echo ":: Synchronizing package databases..."
pkg update && pkg upgrade -y

dependencies=(
  "curl"
  "git"
)

echo ":: Installing essential dependencies..."
if ! _command_exists "gum"; then
  pkg install -y gum
fi

for dependency in "${dependencies[@]}"; do
  _install_package "$dependency"
done

if [ ! -d "$HOME/storage" ]; then
  gum spin --spinner dot --title "Setting up storage..." -- termux-setup-storage
fi

packages=(
  "bat"
  "eza"
  "fastfetch"
  "fd"
  "ffmpeg"
  "fzf"
  "go:golang"
  "jq"
  "just"
  "lua5.3:lua53"
  "make"
  "mandoc"
  "nvim:neovim"
  "node:nodejs"
  "python"
  "rustc:rust"
  "rust-analyzer"
  "tree-sitter"
  "unzip"
  "uv"
  "wget"
  "yazi"
  "zsh"
  "zoxide"
)

echo ":: Installing development packages..."
for package in "${packages[@]}"; do
  _install_package "$package"
done
gum spin --spinner pulse --title "Enabling pnpm..." -- corepack enable pnpm
gum spin --spinner dot --title "Installing yt-dlp..." -- python3 -m pip install -U --pre "yt-dlp[default]"
gum spin --spinner dot --title "Updating PATH for installed apps..." -- termux-fix-shebang /data/data/com.termux/files/usr/bin/*

echo ":: Setting up oh-my-zsh and plugins..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  gum spin --spinner pulse --title "Installing oh-my-zsh..." -- sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  gum spin --spinner dot --title "Installing powerlevel10k theme..." -- git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
  gum spin --spinner dot --title "Installing zsh-autocomplete..." -- git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  gum spin --spinner dot --title "Installing zsh-autosuggestions..." -- git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  gum spin --spinner pulse --title "Installing zsh-syntax-highlighting..." -- git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

gum spin --spinner dot --title "Configuring .zshrc..." -- true
cat >~/.zshrc <<'EOF'
HISTORY_IGNORE="(ls|cd|pwd|zsh|exit|cd ..)"
HISTSIZE=10000
SAVEHIST=10000
LISTMAX=1000

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(git zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'

alias c='clear'
alias cd='z'
alias cat='bat'
alias -s git='git clone'
alias ls='eza'
alias l='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias reload='exec zsh -l'
alias tree='eza -T --icons --level=2'
alias v=$EDITOR
alias wget='wget -c'
alias x='exit'
alias upgrade='pkg update && pkg upgrade -y'
alias pku='pkg update && pkg upgrade -y'

eval "$(zoxide init zsh)"
source <(fzf --zsh)
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

bindkey -M vicmd ":" undefined-key

function take() {
        mkdir -p $1
        cd $1
}

# Up, the Plugin
# Author: Peter Hurford
# https://github.com/peterhurford/up.zsh
function up(){ # Go up X directories (default 1)
  if [[ "$#" -ne 1 ]]; then
    cd ..
  elif ! [[ $1 =~ '^[0-9]+$' ]]; then
    echo "Error: up should be called with the number of directories to go up. The default is 1."
  else
    local d=""
    limit=$1
    for ((i=1 ; i <= limit ; i++))
      do
        d=$d/..
      done
    d=$(echo $d | sed 's/^\///')
    cd $d
  fi
}

function yy() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                cd "$cwd"
        fi
        rm -f -- "$tmp"
}
EOF

gum spin --spinner dot --title "Configuring Termux properties..." -- true
mkdir -p ~/.termux
cat >~/.termux/termux.properties <<'EOF'
extra-keys = [[ \
{key: 'ESC', popup: {macro: 'ESC :: q ENTER', display: ':q'}}, \
{key: '/', popup: 'BACKSLASH'}, \
{key: '-', popup: "|"}, \
{key: 'HOME', popup: '~'}, \
'UP', \
{key: 'END', popup: {macro: 'ESC :: w q ENTER', display: ':wq'}}, \
{key: 'KEYBOARD', popup: 'DRAWER'} \
], [ \
'TAB', \
'CTRL', \
'ALT', \
'LEFT', \
'DOWN', \
'RIGHT', \
{key: 'ENTER', popup: {macro: ' ESC :: w ENTER', display: ':w'}} \
]]
EOF

gum spin --spinner dot --title "Configuring fastfetch..." -- mkdir -p "$HOME/.config/fastfetch" && curl -fsSL "https://raw.githubusercontent.com/joncrangle/.dotfiles/main/dot_config/fastfetch/config.jsonc" -o "$HOME/.config/fastfetch/config.jsonc"

gum spin --spinner pulse --title "Setting zsh as default shell..." -- chsh -s "$(which zsh)"

echo
echo -e "$GREEN"
cat <<"EOF"
┌─────────────────────────────────────┐
│           Setup Complete!           │
└─────────────────────────────────────┘
EOF
echo
echo "🎉 Your Termux environment is ready!"
echo "⚡ Run 'p10k configure' to customize your prompt theme"
echo "📱 Please ensure that Termux:API and Termux:Styling are installed using F-Droid"
echo "👑 Long press anywhere in Termux, select More -> Styling to select a font and colorscheme"
echo "🖊️ Time to import your Neovim config"
echo
echo -e "$NONE"

