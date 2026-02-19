#!/usr/bin/env zsh

# Determine absolute paths
SCRIPT_ABS_PATH="${0:A}"
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH")
PARENT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
INSTALL_DIR="$PARENT_DIR/install"

# Detect platform
case "$(uname -s)" in
	Darwin) DOTFILES_PLATFORM="macos" ;;
	Linux)  DOTFILES_PLATFORM="linux" ;;
	*)      echo "Unsupported platform: $(uname -s)"; exit 1 ;;
esac

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Ensure stow is installed
if ! command -v stow &>/dev/null; then
	echo "Installing stow..."
	if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
		brew install stow
	else
		sudo apt install -y stow 2>/dev/null || sudo dnf install -y stow 2>/dev/null || sudo pacman -S --noconfirm stow 2>/dev/null
	fi
fi

# Install dotfiles via stow
STOW_DIR="$PARENT_DIR/packages"
echo "Stowing common dotfiles..."
command stow -d "$STOW_DIR" -t "$HOME" --restow common

if [[ -d "$STOW_DIR/$DOTFILES_PLATFORM" ]]; then
	echo "Stowing $DOTFILES_PLATFORM dotfiles..."
	command stow -d "$STOW_DIR" -t "$HOME" --restow "$DOTFILES_PLATFORM"
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

# Run platform-specific installer
PLATFORM_INSTALLER="$INSTALL_DIR/$DOTFILES_PLATFORM/installer.sh"
if [ -f "$PLATFORM_INSTALLER" ]; then
	echo "Running $DOTFILES_PLATFORM installer..."
	source "$PLATFORM_INSTALLER"
fi

echo "Installation complete."
echo "Note: Plugins will auto-install on first shell startup via zinit."
