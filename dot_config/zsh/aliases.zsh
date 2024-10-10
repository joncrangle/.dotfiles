#!/usr/bin/env zsh
# NOTE:
#   (`-')   (`-').-> (`-').->
#   ( OO).->( OO)_   (OO )__
# ,(_/----.(_)--\_) ,--. ,'-'
# |__,    |/    _ / |  | |  |
#  (_/   / \_..`--. |  `-'  |
#  .'  .'_ .-._)   \|  .-.  |
# |       |\       /|  | |  |
# `-------' `-----' `--' `--'
# ##############################
# #         ZSH ALIASES        #
# ##############################

alias c="clear"
alias cat="bat"
alias cd="z"
alias cm="chezmoi"
alias cme="cd $HOME/.config/.local/share/chezmoi"
alias cmu="chezmoi update && chezmoi apply"
alias dock="docker-compose pull && docker-compose up -d; docker system prune -a -f"
alias -s git="git clone"
alias lazy="lazygit"
alias lg="lazygit"
alias lzg="lazygit"
alias lzd="lazydocker"
alias ls="eza"
alias l="eza --icons"
alias ll="eza -l --icons"
alias la="eza -la --icons"
alias python3="uv"
alias reload='exec zsh -l'
alias tg='topgrade'
alias top="btop"
alias tree="eza -T --icons --level=2"
alias v=$EDITOR
alias vi=$EDITOR
alias vim=$EDITOR
alias wget="wget -c"
alias x="exit"

########## Functions ##########
sudo_nvim() {
	sudoedit "$@"
}

alias 'sudo nvim'=sudo_nvim
alias 'sudo vim'=sudo_nvim
alias 'sudo vi'=sudo_nvim
alias 'sudo v'=sudo_nvim

brew-upgrade() {
	brew upgrade --cask wezterm@nightly --no-quarantine --greedy-latest
	brew update
	brew upgrade
	brew cleanup
}

copy-line() {
	if command -v pbcopy >/dev/null; then
		rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' | awk -F ':' '{print $3}' | sed 's/^\s+//' | pbcopy
	elif command -v wl-copy >/dev/null; then
		rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' | awk -F ':' '{print $3}' | sed 's/^\s+//' | wl-copy
	else
		echo "pbcopy or wl-copy command not found. Unable to copy to clipboard."
	fi
}

extract() {
	if [ -f $1 ]; then
		case $1 in
		*.tar.bz2) tar xvjf $1 ;;
		*.tar.gz) tar xvzf $1 ;;
		*.tar.xz) tar xvf $1 ;;
		*.bz2) bunzip2 $1 ;;
		*.rar) unrar x $1 ;;
		*.gz) gunzip $1 ;;
		*.tar) tar xvf $1 ;;
		*.tbz2) tar xvjf $1 ;;
		*.tgz) tar xvzf $1 ;;
		*.zip) unzip $1 ;;
		*.Z) uncompress $1 ;;
		*.7z) 7z x $1 ;;
		*) echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

extract-audio-and-video() {
	ffmpeg -i "$1" -c:a copy audio.aac
	ffmpeg -i "$1" -c:v copy video.mp4
}

git-tag() {
	local version=""
	local message=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-v | --version)
			shift
			version="$1"
			;;
		-m | --message)
			shift
			message="$1"
			;;
		*)
			echo "Invalid option: $1"
			echo "Usage: git-tag -v <version> -m <message>"
			return 1
			;;
		esac
		shift
	done

	# Check if version and message are provided
	if [ -z "$version" ] || [ -z "$message" ]; then
		echo "Usage: git-tag -v <version> -m <message>"
		return 1
	fi

	git tag -a "$version" -m "$message"
	git push origin "$version"
}

libby() {
	cd $HOME/Downloads
	odmpy libby -c -m --mergeformat m4b --mergecodec libfdk_aac -k --nobookfolder
	z -
}

open-at-line() {
	nvim $(rg --line-number . | fzf --delimiter ':' --preview 'bat --color=always --highlight-line {2} {1}' | awk -F ':' '{print "+"$2" "$1}')
}

pass() {
	echo "Generate password"
	LENGTH=32
	CHOICE=$(gum choose "short (12)" "medium (20)" "long (32)" "custom")

	case "$CHOICE" in
	"short (12)")
		LENGTH=12
		;;
	"medium (20)")
		LENGTH=20
		;;
	"long (32)")
		LENGTH=32
		;;
	"custom")
		LENGTH=$(gum input --placeholder "Enter custom length")
		;;
	esac

	PASSWORD=$(openssl rand -base64 "$LENGTH")

	if command -v pbcopy >/dev/null; then
		echo -n "$PASSWORD" | pbcopy
		echo -e "$PASSWORD\nCopied to clipboard"
	elif command -v wl-copy >/dev/null; then
		echo -n "$PASSWORD" | wl-copy
		echo -e "$PASSWORD\nCopied to clipboard"
	else
		echo "pbcopy or wl-copy command not found. Unable to copy to clipboard."
	fi
}

password() {
	generate_password() {
		local length=$1
		openssl rand -base64 "$length"
	}

	copy_to_clipboard() {
		if command - v pbcopy >/dev/null; then
			echo -n "$1" | pbcopy
		elif command -v wl-copy >/dev/null; then
			echo -n "$1" | wl-copy
		else
			echo "pbcopy or wl-copy command not found. Unable to copy to clipboard."
		fi
	}

	usage() {
		echo "usage: pass [option]"
		echo "generate a random password and copy it to clipboard."
		echo ""
		echo "options:"
		echo "  -s, --short    generate a short password (12 characters)"
		echo "  -m, --medium   generate a medium password (20 characters)"
		echo "  -l, --long     generate a long password (32 characters) - default option"
		echo "  -c, --custom   generate a custom length password (specify length)"
		echo "  -h, --help     display this help message"
	}

	# default password length
	local length=32

	# parse options
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-s | --short)
			length=12
			shift
			;;
		-m | --medium)
			length=20
			shift
			;;
		-l | --long)
			length=32
			shift
			;;
		-c | --custom)
			if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
				length="$2"
				shift 2
			else
				echo "error: invalid or missing length for custom option"
				usage
				return 1
			fi
			;;
		-h | --help)
			usage
			return 0
			;;
		*)
			echo "error: invalid option '$1'"
			usage
			return 1
			;;
		esac
	done

	# Generate password
	local password=$(generate_password "$length")

	# Copy to clipboard
	copy_to_clipboard "$password" && echo -e "$password\nCopied to clipboard"
}

take() {
	mkdir -p $1
	cd $1
}

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd "$cwd"
	fi
	rm -f -- "$tmp"
}
