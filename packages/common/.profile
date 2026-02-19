#!/usr/bin/env zsh

export DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"

# Detect platform
case "$(uname -s)" in
    Darwin) DOTFILES_PLATFORM="macos" ;;
    Linux)  DOTFILES_PLATFORM="linux" ;;
    *)      DOTFILES_PLATFORM="" ;;
esac
export DOTFILES_PLATFORM

# Source common, then platform-specific, for each config dir
for dir in exports aliases functions; do
    for layer in common "$DOTFILES_PLATFORM"; do
        target="$DOTFILES/$dir/$layer"
        if [[ -d "$target" ]]; then
            for f in "$target"/*(.N); do
                [[ -f "$f" ]] && source "$f"
            done
        fi
    done
done

# Local overrides (not platform-split)
if [[ -d "$DOTFILES/local" ]]; then
    for f in "$DOTFILES/local"/*(.N); do
        [[ -f "$f" ]] && source "$f"
    done
fi

unset dir target f layer
