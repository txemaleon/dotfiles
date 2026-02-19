#!/usr/bin/env zsh

set -e

echo "Uninstalling dotfiles..."

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/dotfiles}"
PARENT_DIR="$DOTFILES_DIR"

# Remove stow symlinks
STOW_DIR="$PARENT_DIR/packages"
if [ -d "$STOW_DIR" ]; then
	echo "Removing stow symlinks..."
	command stow -d "$STOW_DIR" -t "$HOME" -D common 2>/dev/null
	command stow -d "$STOW_DIR" -t "$HOME" -D macos 2>/dev/null
	command stow -d "$STOW_DIR" -t "$HOME" -D linux 2>/dev/null
else
	echo "Warning: Packages directory not found at $STOW_DIR"
fi

# Remove zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
if [ -d "$ZINIT_HOME" ]; then
	echo "Removing zinit..."
	rm -rf "$ZINIT_HOME"
fi

# Remove shell cache
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [ -d "$CACHE_DIR" ]; then
	echo "Removing shell cache..."
	rm -rf "$CACHE_DIR"
fi

echo ""
echo "Dotfiles uninstalled."
echo "The dotfiles repository at $DOTFILES_DIR has NOT been removed."
echo "Homebrew packages and casks have NOT been removed."
echo "To fully clean up, run: rm -rf $DOTFILES_DIR"
