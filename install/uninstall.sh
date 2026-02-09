#!/usr/bin/env zsh

set -e

echo "Uninstalling dotfiles..."

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.config/dotfiles}"
CONFIG_DIR="$DOTFILES_DIR/config"

if [ ! -d "$CONFIG_DIR" ]; then
	echo "Error: Config directory not found at $CONFIG_DIR"
	exit 1
fi

# Remove symlinks created by installer
echo "Removing symlinked config files..."
for file in "$CONFIG_DIR"/*; do
	f=$(basename "$file")
	target="$HOME/.$f"
	if [ -L "$target" ]; then
		echo "  Removing $target"
		rm "$target"
	fi
done

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
