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
# #      ZSH KEYMAPS CONFIG    #
# ##############################

# Vim bindings
bindkey -v
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Text objects (da", ci(, etc.)
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done

# Surround (cs = change surround, ds = delete surround, ys = add surround)
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -M vicmd cs change-surround
bindkey -M vicmd ds delete-surround
bindkey -M vicmd ys add-surround
bindkey -M visual S add-surround
