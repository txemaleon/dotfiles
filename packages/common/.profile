#!/usr/bin/env zsh

export DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"

# Source all config files from dotfiles directories
for dir in exports aliases functions local; do
    target="$DOTFILES/$dir"
    if [[ -d "$target" ]]; then
        for f in "$target"/*(.N); do
            [[ -f "$f" ]] && source "$f"
        done
    fi
done

unset dir target f
