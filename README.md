# macOS dotfiles

This repo installs all my personal configurations and most used applications

## Quick Install (Recommended)

Install everything with a single command:

```bash
curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | bash
```

### Custom installation options

Use a specific branch:

```bash
DOTFILES_BRANCH="your-branch" curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | bash
```

## Manual Installation

If you prefer to install manually:

```bash
mkdir -p ~/.config && cd ~/.config
git clone git@github.com:txemaleon/dotfiles.git
cd dotfiles/install
./installer.sh
```

## Post-Installation Setup

To sign commits in the new machine, generate your ssh key and run:

```bash
ssh-keygen -t rsa -b 4096
git config --global user.signingkey "~/.ssh/id_rsa.pub"
```

## To prepare a migration to a new computer

```bash
cd ~/.config/dotfiles/install
./prepare-migration.sh
git commit -a -m "Update packages and new migration"
git push
```

Then in the new computer use the quick install method above
