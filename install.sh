#!/usr/bin/env zsh

set -euo pipefail
trap 'echo "❌ install.sh failed at line $LINENO (exit $?)" >&2' ERR

ascii_art='████████╗██╗  ██╗███████╗███╗   ███╗ █████╗ ██╗     ███████╗ ██████╗ ███╗   ██╗
╚══██╔══╝╚██╗██╔╝██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝██╔═══██╗████╗  ██║
   ██║    ╚███╔╝ █████╗  ██╔████╔██║███████║██║     █████╗  ██║   ██║██╔██╗ ██║
   ██║    ██╔██╗ ██╔══╝  ██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██║   ██║██║╚██╗██║
   ██║   ██╔╝ ██╗███████╗██║ ╚═╝ ██║██║  ██║███████╗███████╗╚██████╔╝██║ ╚████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

                        🔧 macOS dotfiles installer 🔧                          '

echo -e "\n$ascii_art\n"

check_requirements() {
	if ! command -v git &>/dev/null; then
		echo "❌ Git is not installed. Please install git first:"
		echo "  brew install git"
		echo "  or install Xcode Command Line Tools: xcode-select --install"
		exit 1
	fi

	if [[ $OSTYPE != "darwin"* ]]; then
		echo "❌ This installer is designed for macOS only."
		exit 1
	fi
}

main() {
	echo "🔍 Checking requirements..."
	check_requirements

	DOTFILES_DIR="$HOME/.config/dotfiles"
	DOTFILES_BRANCH="${DOTFILES_BRANCH:-master}"

	echo "📁 Setting up dotfiles directory..."
	mkdir -p "$(dirname "$DOTFILES_DIR")"

	if [ -d "$DOTFILES_DIR" ]; then
		echo "🗂️  Dotfiles directory already exists. Updating..."
		cd "$DOTFILES_DIR"
		git fetch origin "$DOTFILES_BRANCH" && git reset --hard "origin/$DOTFILES_BRANCH"
	else
		echo "📦 Cloning dotfiles repository..."
		git clone "https://github.com/txemaleon/dotfiles.git" "$DOTFILES_DIR" >/dev/null 2>&1
		cd "$DOTFILES_DIR"
	fi

	if [[ -n $DOTFILES_BRANCH && $DOTFILES_BRANCH != "master" ]]; then
		echo "🌿 Using branch: $DOTFILES_BRANCH"
		git fetch origin "$DOTFILES_BRANCH" && git checkout "$DOTFILES_BRANCH"
	fi

	echo "🚀 Starting installation..."
	if [ -f "$DOTFILES_DIR/install/installer.sh" ]; then
		cd "$DOTFILES_DIR/install"
		./installer.sh
		echo ""
		echo "✅ Installation completed successfully!"
		echo "🎉 Your macOS environment is now configured with txemaleon's dotfiles."
		echo ""
		echo "📝 Next steps:"
		echo "  • Restart your terminal or run: source ~/.zshrc"
		echo "  • Generate SSH key for git signing: ssh-keygen -t rsa -b 4096"
		echo "  • Configure git signing: git config --global user.signingkey ~/.ssh/id_rsa.pub"
	else
		echo "❌ Installation script not found. Please check the repository."
		exit 1
	fi
}

main "$@"
