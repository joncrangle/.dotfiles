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
# #         ZSH OPTIONS        #
# ##############################

setopt extended_history     # Record start/end time
setopt append_history       # Save history from all sessions
setopt hist_ignore_all_dups # Delete older command lines if they overlap
setopt hist_ignore_space    # Remove commands starting with a space from history
unsetopt hist_verify        # Skip edit check when invoking from history
setopt hist_reduce_blanks   # Compress multiple spaces into one
setopt hist_save_no_dups    # Ignore old commands when writing to history file
setopt hist_no_store        # Don't save history commands in history

# Directory Stack Management
setopt auto_pushd        # Put the directory in the directory stack even when cd'ing normally
setopt pushd_ignore_dups # Delete old duplicates in the directory stack
setopt pushd_to_home     # 'pushd' without arguments goes home
setopt pushd_silent      # Don't show contents of directory stack on every pushd/popd
setopt pushdminus        # Swap '+' and '-' behavior for directory stack navigation

# Completion and Display
setopt list_packed       # Compactly display completion list
setopt auto_remove_slash # Automatically remove trailing / in completions
setopt auto_param_slash  # Automatically append trailing / to directory completions
setopt mark_dirs         # Append trailing / to directory names in glob/expansion
setopt list_types        # Display file type identifier (like ls -F)
unsetopt menu_complete   # Don't auto-insert the first match
setopt auto_list         # Display a list of possible completions
setopt auto_menu         # Automatic completion by hitting completion key repeatedly
setopt auto_param_keys   # Automatically completes bracket correspondence, etc.
setopt complete_in_word  # Allows completion in the middle of a word

# General Shell Behavior
unsetopt promptcr           # Prevent overwriting non-newline output at the prompt
setopt no_beep              # Don't beep on command input error
setopt equals               # Expand =COMMAND to COMMAND pathname
setopt nonomatch            # Disable glob error if no match found
setopt glob                 # Enable file name generation
setopt extended_glob        # Enable powerful extended globs
setopt no_flow_control      # Disable C-s/C-q flow control
setopt hash_cmds            # Put path in hash when command is executed
setopt no_hup               # Don't kill background jobs on logout
setopt ignore_eof           # Don't logout with C-d
setopt long_list_jobs       # Use jobs -L by default
setopt magic_equal_subst    # Enable completion after '='
setopt mail_warning         # Warn if new mail arrives
setopt multios              # Enable multi-stream redirection
setopt numeric_glob_sort    # Sort by interpreting numbers as numerical values
setopt path_dirs            # Find subdirectories in PATH when / is included
setopt print_eight_bit      # Display 8-bit characters correctly
setopt auto_name_dirs       # Automate directory name hashing
unsetopt sh_word_split      # Do not split based on unquoted variable expansion (Zsh default, safer)
setopt notify               # Notify as soon as background job finishes
setopt interactive_comments # Allow comments while typing commands
setopt chase_links          # Symbolic links are converted to linked paths before execution
setopt rm_star_wait         # confirm before rm * is executed
