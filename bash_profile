#!/usr/bin/env bash
[ -f ~/.profile ] && source ~/.profile

# Load bash_prompt aliases exports functions inputrc from ~/.config/dotfiles
# and from ~/.* for per-system overrides
for file in bash_prompt aliases exports functions; do
	# Main dotfile
	dotfile="$HOME/.config/dotfiles/$file"
	[ -f "$dotfile" ] && source "$dotfile"
	[ -d "$dotfile" ] && for f in $dotfile/*; do source "$f"; done
	# Local dotfile
	dotfilelocal="$HOME/.config/dotfiles/local/$file"
	[ -f "$dotfilelocal" ] && source "$dotfilelocal"
	[ -d "$dotfilelocal" ] && for f in $dotfilelocal/*; do source "$f"; done
	# Home dotfile
	homefile="$HOME/.$file"
	[ -f "$homefile" ] && source "$homefile"
done
unset dotfile dotfilelocal homefile

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Autocompletions
# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh

# Brew installed Autocompletes
[ -d /usr/local/etc/bash_completion\.d ] && \
for f in /usr/local/etc/bash_completion.d/*; do
	source $f;
done
