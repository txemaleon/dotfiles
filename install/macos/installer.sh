#!/usr/bin/env zsh

# Determine absolute paths
SCRIPT_ABS_PATH="${0:A}"
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH")
PARENT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
INSTALL_DIR="$PARENT_DIR/install"

# Install HomeBrew & Packages
if ! command -v brew &>/dev/null; then
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew already installed."
fi

echo "Installing Brewfile packages..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

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

# macOS-specific git config (Apple keychain)
if [ -f "$SCRIPT_DIR/gitconfig.sh" ]; then
	echo "Running macOS git configuration..."
	sh "$SCRIPT_DIR/gitconfig.sh"
fi

# Configure macOS system defaults
if [ -f "$SCRIPT_DIR/macos.sh" ]; then
	echo "Applying macOS settings..."
	source "$SCRIPT_DIR/macos.sh"
else
	echo "Warning: macos.sh not found at $SCRIPT_DIR/macos.sh"
fi

echo "macOS installation complete."
