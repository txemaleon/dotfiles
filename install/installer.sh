#!/usr/bin/env zsh

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Determine absolute paths
SCRIPT_ABS_PATH="${0:A}"                 # Absolute path to the script itself
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH") # Absolute path to the install directory
PARENT_DIR=$(dirname "$SCRIPT_DIR")      # Absolute path to the dotfiles root directory
INSTALL_DIR="$SCRIPT_DIR"                # Use absolute path for install dir too

# Ensure essential files/dirs exist relative to the script's expected location
if [ ! -d "$PARENT_DIR/config" ] || [ ! -f "$INSTALL_DIR/Brewfile" ] || [ ! -f "$INSTALL_DIR/Bunfile" ] || [ ! -f "$INSTALL_DIR/macos.sh" ] || [ ! -f "$INSTALL_DIR/gitconfig.sh" ]; then
	echo "Error: Required files or directories not found."
	echo "Ensure Brewfile, Bunfile, macos.sh, gitconfig.sh are in $INSTALL_DIR"
	echo "Ensure the config directory exists at $PARENT_DIR/config"
	# Although paths are absolute now, running from root is still good practice for consistency
	echo "Please consider running this script from the dotfiles root directory: $PARENT_DIR"
	exit 1
fi

# Install dotfiles
DOTFILES_CONFIG_DIR="$PARENT_DIR/config" # Absolute path to config dir
for FILE in $DOTFILES_CONFIG_DIR/*; do   # FILE is now an absolute path
	f=$(basename $FILE)
	TARGET_FILE="$HOME/.$f"
	if [ -L "$TARGET_FILE" ] || [ -f "$TARGET_FILE" ]; then
		# echo "Removing existing file/link: $TARGET_FILE"
		rm -rf "$TARGET_FILE"
	fi
	echo "Linking $FILE => $TARGET_FILE" # Echoing absolute source and target
	# Use absolute path for the source file
	ln -s "$FILE" "$TARGET_FILE"
done

# Install HomeBrew & Packages
if ! command -v brew &>/dev/null; then
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew already installed."
fi

echo "Installing Brewfile packages..."
brew bundle --file="$INSTALL_DIR/Brewfile"

# Restore configs from iCloud (only if iCloud is configured)
ICLOUD_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_CONFIG="$ICLOUD_PATH/config"
if [ -d "$ICLOUD_CONFIG" ]; then
	echo "Restoring configs from iCloud..."

	# Mackup config (these are symlinks to find the mackup settings)
	ln -sf "$ICLOUD_CONFIG/.mackup" ~/.mackup
	ln -sf "$ICLOUD_CONFIG/.mackup.cfg" ~/.mackup.cfg

	# Restore copies from iCloud (not symlinks - avoids sync issues)
	mackup restore --force
else
	echo "⚠️  iCloud not configured, skipping config restore"
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

# Install ssh key & git config
if [ -f "$INSTALL_DIR/gitconfig.sh" ]; then
	echo "Running git configuration script..."
	sh "$INSTALL_DIR/gitconfig.sh"
else
	echo "Warning: gitconfig.sh not found at $INSTALL_DIR/gitconfig.sh"
fi

# Configure macos
if [ -f "$INSTALL_DIR/macos.sh" ]; then
	echo "Applying macOS settings..."
	source "$INSTALL_DIR/macos.sh"
else
	echo "Warning: macos.sh not found at $INSTALL_DIR/macos.sh"
fi

# Install zinit plugin manager (plugins auto-install on first shell load)
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
	echo "Installing zinit plugin manager..."
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
	echo "zinit already installed."
fi

# Remove oh-my-zsh if it exists (migrating to zinit + starship)
if [ -d "$HOME/.oh-my-zsh" ]; then
	echo "Removing old oh-my-zsh installation..."
	rm -rf "$HOME/.oh-my-zsh"
fi

echo "Installation complete."
echo "Note: Plugins will auto-install on first shell startup via zinit."
