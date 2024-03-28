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

unsetopt promptcr           # Prevent overwriting non-newline output at the prompt
setopt extended_history     # Record start time and elapsed time in history file
setopt append_history       # Add history (instead of creating .zhistory every time)
setopt hist_ignore_all_dups # Delete older command lines if they overlap
setopt hist_ignore_dups     # Do not add the same command line to history as the previous one
setopt hist_ignore_space    # Remove command lines beginning with a space from history
unsetopt hist_verify        # Stop editability once between history invocation and execution
setopt hist_reduce_blanks   # Extra white space is stuffed and recorded
setopt hist_save_no_dups    # Ignore old commands that are the same as old commands when writing to history file.
setopt hist_no_store        # history commands are not registered in history
setopt hist_expand          # automatically expand history on completion
setopt list_packed          # Compactly display completion list
setopt auto_remove_slash    # Automatically remove trailing / in completions
setopt auto_param_slash     # Automatically append trailing / in directory name completion to prepare for next completion
setopt mark_dirs            # Append trailing / to filename expansions when they match a directory
setopt list_types           # Display file type identifier in list of possible completions (ls -F)
unsetopt menu_complete      # When completing, instead of displaying a list of possible completions and beeping. Don't insert the first match suddenly.
setopt auto_list            # Display a list of possible completions with ^I (when there are multiple candidates for completion, display a list)
setopt auto_menu            # Automatic completion of completion candidates in order by hitting completion key repeatedly
setopt auto_param_keys      # Automatically completes bracket correspondence, etc.
setopt auto_resume          # Resume when executing the same command name as a suspended process
setopt no_beep              # Don't beep on command input error
setopt complete_in_word
setopt equals    # Expand =COMMAND to COMMAND pathname
setopt nonomatch # Enable glob expansion to avoid nomatch
setopt glob
setopt extended_glob     # Enable expanded globs
unsetopt flow_control    # Disable C-s, C-q (in shell editor)
setopt no_flow_control   # Do not use C-s/C-q flow control
setopt hash_cmds         # Put path in hash when each command is executed
setopt no_hup            # Don't kill background jobs on logout
setopt ignore_eof        # Don't logout with C-d
setopt long_list_jobs    # Make internal command jobs output jobs -L by default
setopt magic_equal_subst # command line arguments can be completed after =, e.g. --PREFIX=/USR
setopt mail_warning
setopt multios           # TEE and CAT features are used as needed, such as multiple redirects and pipes
setopt numeric_glob_sort # Sort by interpreting numbers as numerical values
setopt path_dirs         # Find subdirectories in PATH when / is included in command name
setopt print_eight_bit   # Display Japanese in completion candidate list properly
setopt short_loops       # Use simplified syntax for FOR, REPEAT, SELECT, IF, FUNCTION, etc.
setopt auto_name_dirs
setopt always_last_prompt # Display file name list sequentially on-the-fly while keeping cursor position
unsetopt sh_word_split
setopt auto_pushd        # Put the directory in the directory stack even when cd'ing normally.
setopt pushd_ignore_dups # Delete old duplicates in the directory stack.
setopt pushd_to_home     # no pushd argument == pushd $HOME
setopt pushd_silent      # Don't show contents of directory stack on every pushd,popd
setopt pushdminus        # swap + - behavior
setopt rm_star_wait      # confirm before rm * is executed
setopt notify            # Notify as soon as background job finishes (don't wait for prompt)
unsetopt no_clobber
setopt interactive_comments # Allow comments while typing commands
setopt chase_links          # Symbolic links are converted to linked paths before execution
setopt noflowcontrol
setopt nolistambiguous # Show menu
