#!/usr/bin/env zsh

set -e

REMOTE_HOST="blackbird"
DOTFILES_BRANCH="feat/stow-migration"
DOTFILES_REPO="https://github.com/txemaleon/dotfiles.git"
DOTFILES_DIR="\$HOME/.config/dotfiles"

echo "🐧 Testing dotfiles on $REMOTE_HOST..."
echo ""

ssh "$REMOTE_HOST" bash -s <<REMOTE
set -e

echo "==> Setting up dotfiles directory..."
mkdir -p "\$(dirname $DOTFILES_DIR)"

if [ -d "$DOTFILES_DIR" ]; then
    echo "==> Dotfiles directory exists. Updating..."
    cd "$DOTFILES_DIR"
    git fetch origin "$DOTFILES_BRANCH"
    git checkout "$DOTFILES_BRANCH"
    git reset --hard "origin/$DOTFILES_BRANCH"
else
    echo "==> Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    git checkout "$DOTFILES_BRANCH"
fi

echo ""
echo "==> Running Linux installer..."
source "$DOTFILES_DIR/install/linux/installer.sh"

echo ""
echo "==> Running common installer..."
source "$DOTFILES_DIR/install/common/installer.sh"

echo ""
echo "==> Verification..."
echo "Platform: \$(uname -s)"
echo ""

echo "Symlinks:"
for f in .zshrc .gitconfig .gitignore .tmux.conf .editorconfig .inputrc .profile .npmrc; do
    if [ -L "\$HOME/\$f" ]; then
        echo "  ✅ ~/\$f -> \$(readlink "\$HOME/\$f")"
    else
        echo "  ❌ ~/\$f is NOT a symlink"
    fi
done

echo ""
echo "Directory structure:"
ls -d "$DOTFILES_DIR"/{aliases,exports,functions}/{common,macos,linux} 2>/dev/null && echo "  ✅ Platform dirs exist" || echo "  ❌ Platform dirs missing"

echo ""
echo "Linux-specific files:"
for f in aliases/linux/os aliases/linux/utilities exports/linux/exports exports/linux/node functions/linux/updates; do
    if [ -f "$DOTFILES_DIR/\$f" ]; then
        echo "  ✅ \$f"
    else
        echo "  ❌ \$f missing"
    fi
done

echo ""
echo "==> Done! Restart shell or run: source ~/.profile"
REMOTE

echo ""
echo "✅ Remote test complete on $REMOTE_HOST"
