# macOS dotfiles

Personal macOS configuration: shell, git, tmux, neovim, and 270+ aliases.

## Structure

```
dotfiles/
├── aliases/        # Command aliases (dev, docker, git, navigation, os, utilities, vim)
├── config/         # Dotfile configs (zshrc, gitconfig, tmux.conf, editorconfig, etc.)
├── exports/        # Environment variables (PATH, XDG, node, homebrew, claude, ntfy)
├── functions/      # Shell functions (git workflows, updates, notifications, etc.)
├── install/        # Installation and migration scripts
│   ├── installer.sh
│   ├── uninstall.sh
│   ├── macos.sh
│   ├── gitconfig.sh
│   ├── cleanup.sh
│   ├── prepare-migration.sh
│   ├── Brewfile
│   └── Bunfile
└── local/          # Machine-specific overrides (git-ignored, see *.example files)
```

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | bash
```

Use a specific branch:

```bash
DOTFILES_BRANCH="your-branch" curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | bash
```

## Manual Installation

```bash
mkdir -p ~/.config && cd ~/.config
git clone git@github.com:txemaleon/dotfiles.git
cd dotfiles/install
./installer.sh
```

## Post-Installation

1. Generate SSH key and configure git signing:

```bash
ssh-keygen -t rsa -b 4096
git config --global user.signingkey "~/.ssh/id_rsa.pub"
```

2. Copy and customize local overrides:

```bash
cd ~/.config/dotfiles/local
cp aliases.example aliases
cp ntfy.example ntfy
```

## Uninstall

```bash
cd ~/.config/dotfiles/install
./uninstall.sh
```

## Prepare Migration

Export current state before moving to a new machine:

```bash
cd ~/.config/dotfiles/install
./prepare-migration.sh
git commit -a -m "chore: update packages for migration"
git push
```

Then run the quick install on the new machine.
