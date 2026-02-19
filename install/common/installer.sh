#!/usr/bin/env zsh

# Determine absolute paths
SCRIPT_ABS_PATH="${0:A}"
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH")
PARENT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
INSTALL_DIR="$PARENT_DIR/install"

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Install dotfiles via stow (placeholder — will be implemented in next commit)
DOTFILES_CONFIG_DIR="$PARENT_DIR/config"
for FILE in "$PARENT_DIR"/packages/common/.*; do
	f=$(basename "$FILE")
	[[ "$f" == "." || "$f" == ".." ]] && continue
	TARGET_FILE="$HOME/$f"
	if [ -L "$TARGET_FILE" ] || [ -f "$TARGET_FILE" ]; then
		rm -rf "$TARGET_FILE"
	fi
	echo "Linking $FILE => $TARGET_FILE"
	ln -s "$FILE" "$TARGET_FILE"
done

# Install zinit plugin manager (plugins auto-install on first shell load)
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
	echo "Installing zinit plugin manager..."
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
	echo "zinit already installed."
fi

# Install node tools
echo "Installing global bun packages from $INSTALL_DIR/Bunfile..."
if [ -f "$INSTALL_DIR/Bunfile" ]; then
	NPM_PACKAGES=$(sed 's/#.*//' "$INSTALL_DIR/Bunfile")
	if [ -n "$NPM_PACKAGES" ]; then
		echo "$NPM_PACKAGES" | xargs bun add -g
	else
		echo "No packages found in Bunfile."
	fi
else
	echo "Warning: Bunfile not found at $INSTALL_DIR/Bunfile"
fi

# Install ssh key & git config (common)
if [ -f "$SCRIPT_DIR/gitconfig.sh" ]; then
	echo "Running git configuration script..."
	sh "$SCRIPT_DIR/gitconfig.sh"
fi

echo "Common installation complete."
echo "Note: Plugins will auto-install on first shell startup via zinit."
