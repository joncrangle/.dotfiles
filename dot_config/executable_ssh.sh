#!/bin/sh
# NOTE:
#            /$$   /$$
#           |__/  | $$
#   /$$$$$$  /$$ /$$$$$$
#  /$$__  $$| $$|_  $$_/
# | $$  \ $$| $$  | $$
# | $$  | $$| $$  | $$ /$$
# |  $$$$$$$| $$  |  $$$$/
#  \____  $$|__/   \___/
#  /$$  \ $$
# |  $$$$$$/
#  \______/

# Prompt user for email address if they didn't provide it on the command line
if [ -z "$1" ]; then
	echo "Please provide an email address:"
	read email
else
	email=$1
fi

echo "Generating a new SSH key for GitHub..."
# Generating a new SSH key
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key
ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519

# Adding your SSH key to the ssh-agent
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
eval "$(ssh-agent -s)"

touch ~/.ssh/config
echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ~/.ssh/id_ed25519" | tee ~/.ssh/config >/dev/null

ssh-add --apple-use-keychain ~/.ssh/id_ed25519

pbcopy <~/.ssh/id_ed25519.pub

# Adding your SSH key to your GitHub account
# https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
echo "SSH key copied to clipboard. Please add it to your GitHub account."
echo "You can also run 'pbcopy < ~/.ssh/id_ed25519.pub' to copy the SSH key to your clipboard."
