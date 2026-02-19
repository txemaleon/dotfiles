#!/usr/bin/env zsh

SCRIPT_ABS_PATH="${0:A}"
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH")
PARENT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")

echo "Installing Linux packages..."

# Detect package manager and install essentials
PACKAGES=(zsh stow git neovim tmux fzf ripgrep bat jq tree zoxide curl wget)

if command -v apt &>/dev/null; then
	sudo apt update
	sudo apt install -y "${PACKAGES[@]}"
	# bat is named batcat on Debian/Ubuntu — symlink to expected name
	if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
		mkdir -p "$HOME/.local/bin"
		ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
	fi
elif command -v dnf &>/dev/null; then
	sudo dnf install -y "${PACKAGES[@]}"
elif command -v pacman &>/dev/null; then
	sudo pacman -S --noconfirm "${PACKAGES[@]}"
fi

# Install mise (version manager)
if ! command -v mise &>/dev/null; then
	echo "Installing mise..."
	curl https://mise.run | sh
fi

# Install bun
if ! command -v bun &>/dev/null; then
	echo "Installing bun..."
	curl -fsSL https://bun.sh/install | bash
fi

# Install gh CLI
if ! command -v gh &>/dev/null; then
	echo "Installing GitHub CLI..."
	if command -v apt &>/dev/null; then
		curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
		sudo apt update && sudo apt install -y gh
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y gh
	elif command -v pacman &>/dev/null; then
		sudo pacman -S --noconfirm github-cli
	fi
fi

# Install trash-cli for safe rm
if ! command -v trash-put &>/dev/null; then
	echo "Installing trash-cli..."
	if command -v apt &>/dev/null; then
		sudo apt install -y trash-cli
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y trash-cli
	elif command -v pacman &>/dev/null; then
		sudo pacman -S --noconfirm trash-cli
	fi
	# Alias trash-put to trash for compatibility with macOS trash command
	mkdir -p "$HOME/.local/bin"
	echo '#!/bin/sh\nexec trash-put "$@"' > "$HOME/.local/bin/trash"
	chmod +x "$HOME/.local/bin/trash"
fi

# Install delta (git diff tool)
if ! command -v delta &>/dev/null; then
	echo "Installing git-delta..."
	if command -v apt &>/dev/null; then
		DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | jq -r .tag_name)
		curl -Lo /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb"
		sudo dpkg -i /tmp/delta.deb
		rm /tmp/delta.deb
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y git-delta
	elif command -v pacman &>/dev/null; then
		sudo pacman -S --noconfirm git-delta
	fi
fi

echo "Linux package installation complete."
