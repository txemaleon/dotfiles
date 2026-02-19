# dotfiles

Personal shell configuration for macOS and Linux: shell, git, tmux, neovim, and 270+ aliases.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) for symlink management.

## Structure

```
dotfiles/
├── aliases/
│   ├── common/     # Portable aliases (dev, docker, git, navigation, vim, utilities)
│   ├── macos/      # macOS-specific (emptytrash, flush, afk, Raycast)
│   └── linux/      # Linux-specific (xdg-open, pactl, systemd-resolve)
├── config/         # Reference configs (delta, fixpackrc, nirc — not symlinked)
├── exports/
│   ├── common/     # Portable exports (XDG, EDITOR, PATH)
│   ├── macos/      # Homebrew, coreutils, macOS PNPM path
│   └── linux/      # Linuxbrew, Linux PNPM path
├── functions/
│   ├── common/     # Portable functions (git workflows, completions, navigation)
│   ├── macos/      # macOS-specific (updates, cleanDesktop, journals)
│   └── linux/      # Linux-specific (updates via apt/dnf/pacman)
├── install/
│   ├── common/     # Shared installer (stow, zinit, bun, gitconfig)
│   ├── macos/      # Homebrew, Brewfile, iCloud, mackup, macos.sh
│   └── linux/      # apt/dnf/pacman package installation
├── local/          # Machine-specific overrides (git-ignored, see *.example)
├── packages/
│   ├── common/     # Stow package: .zshrc .gitconfig .tmux.conf etc.
│   ├── macos/      # macOS-only dotfiles (future)
│   └── linux/      # Linux-only dotfiles (future)
└── install.sh      # Bootstrap script
```

### How it works

`.profile` detects the platform and sources files in order:
1. `exports/common/*` → `exports/{macos,linux}/*`
2. `aliases/common/*` → `aliases/{macos,linux}/*`
3. `functions/common/*` → `functions/{macos,linux}/*`
4. `local/*` (machine-specific overrides, last)

Dotfiles in `packages/common/` are symlinked to `$HOME` via GNU Stow.

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | zsh
```

Use a specific branch:

```bash
DOTFILES_BRANCH="feat/stow-migration" curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | zsh
```

## Manual Installation

```bash
mkdir -p ~/.config && cd ~/.config
git clone git@github.com:txemaleon/dotfiles.git
source dotfiles/install/common/installer.sh
```

## Managing dotfiles with Stow

A `stow` alias is preconfigured to target `$HOME` from the packages dir:

```bash
# Re-stow all common dotfiles
stow --restow common

# Add a new config file to your dotfiles
dotadd ~/.config/lazygit/config.yml
```

`dotadd` moves the file into `packages/common/` (mirroring the home directory path) and creates a symlink back.

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
~/.config/dotfiles/install/uninstall.sh
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
