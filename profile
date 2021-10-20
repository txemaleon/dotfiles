#!/usr/bin/env bash

DOTFILES=$HOME/.config/dotfiles
for dir in config aliases functions local; do
    dir=$DOTFILES/$dir
    [ -d "$dir" ] && for f in $dir/*; do source "$f"; done
done

# If exists, allow per enviroment $HOME/.exports
[ -f $HOME/.exports ] && source $HOME/.exports
