#!/usr/bin/env bash

DOTFILES=$HOME/.config/dotfiles
for dir in aliases functions local; do
	dir=$DOTFILES/$dir/
	[ -d "$dir" ] && for f in $dir/*; do source "$f"; done
done

# If exists, allow per enviroment ~/.exports
[ -f ~/.exports ] && source ~/.exports
ZSH_TMUX_AUTOSTART=true
