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
if [ ! -d "$PARENT_DIR/config" ] || [ ! -f "$INSTALL_DIR/Brewfile" ] || [ ! -f "$INSTALL_DIR/Npmfile" ] || [ ! -f "$INSTALL_DIR/macos.sh" ] || [ ! -f "$INSTALL_DIR/gitconfig.sh" ]; then
	echo "Error: Required files or directories not found."
	echo "Ensure Brewfile, Npmfile, macos.sh, gitconfig.sh are in $INSTALL_DIR"
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

# Link mackup
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/.config/.mackup ~/.mackup
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/.config/.mackup.cfg ~/.mackup.cfg
mackup restore

# Install node tools
echo "Installing global npm packages from $INSTALL_DIR/Npmfile..."
if [ -f "$INSTALL_DIR/Npmfile" ]; then
	NPM_PACKAGES=$(sed 's/#.*//' "$INSTALL_DIR/Npmfile")
	if [ -n "$NPM_PACKAGES" ]; then
		echo "$NPM_PACKAGES" | xargs npm install -g
	else
		echo "No packages found in Npmfile."
	fi
else
	echo "Warning: Npmfile not found at $INSTALL_DIR/Npmfile"
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

# Install Oh-my-zsh if not already installed
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo "Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
	echo "Oh My Zsh already installed."
fi

# Install Oh-my-zsh plugins if not already installed
PLUGINS_DIR="$ZSH_CUSTOM/plugins"
mkdir -p "$PLUGINS_DIR"

FZF_TAB_DIR="$PLUGINS_DIR/fzf-tab"
if [ ! -d "$FZF_TAB_DIR" ]; then
	echo "Installing fzf-tab plugin..."
	git clone https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR"
else
	echo "fzf-tab plugin already installed."
fi

AUTOSUGGESTIONS_DIR="$PLUGINS_DIR/zsh-autosuggestions"
if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
	echo "Installing zsh-autosuggestions plugin..."
	git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR"
else
	echo "zsh-autosuggestions plugin already installed."
fi

SYNTAX_HIGHLIGHTING_DIR="$PLUGINS_DIR/zsh-syntax-highlighting"
if [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
	echo "Installing zsh-syntax-highlighting plugin..."
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR"
else
	echo "zsh-syntax-highlighting plugin already installed."
fi

echo "Installation complete."
