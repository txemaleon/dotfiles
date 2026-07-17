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
├── scripts/        # Personal executable scripts and automation entry points
└── local/          # Machine-specific overrides (git-ignored; rare — prefer mackup for apps)
```

## Quick Install

Sign in to your Apple Account and enable iCloud Drive before running the
installer. It waits up to 30 minutes for the configuration folders, marks
`.config` and `config` as Keep Downloaded, and does not restore Mackup until
File Provider reports that their latest contents are available locally.

```bash
curl -sSL https://raw.githubusercontent.com/txemaleon/dotfiles/master/install.sh | bash
```

macOS settings are applied by default. Set `DOTFILES_APPLY_MACOS=false` only
when intentionally installing packages and dotfiles without changing system
preferences.

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

2. Optional machine-specific overrides and secrets:

```bash
# Paths (defaults in exports/paths) — create if your layout differs:
# echo 'export PROJECTS_DIR="$HOME/code/projects"' >> ~/.config/dotfiles/local/paths

# Secrets in macOS Keychain (syncs via iCloud Keychain):
dotfiles-secret set ntfy-token 'tk_...'
dotfiles-secret set resend-api-token 're_...'
dotfiles-secret list
```

Machine-only overrides: optional `local/paths`, `local/aliases` (git-ignored).

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

## App config snapshots (Mackup → iCloud)

Mackup stores explicit backup/restore snapshots for Claude, Cursor, Ghostty,
LinearMouse, Neovim, and other configured apps. Restore creates independent
local copies, not links to iCloud, so later iCloud changes cannot mutate live
application configuration.

Definitions: `install/mackup.cfg` + `install/mackup/*.cfg` · backup:
`./prepare-migration.sh` (waits for iCloud upload) or `mackup backup --force`

**Finicky** (browser/URL router): rules in `config/finicky.js` → symlinked to `~/.finicky.js`. Set as default browser via `macos.sh` (duti). It is not launched at login; macOS starts it on demand when a URL is opened.

System/terminal (Dock, Karabiner layouts, shell, defaults): `install/macos.sh` + dotfiles repo.

Executable scripts live in `scripts/`. Scripts with Raycast metadata headers are also symlinked to `~/.raycast/scripts` by `install/installer.sh`.

## macOS major upgrades

This setup intentionally avoids major macOS upgrades such as Tahoe. The `update`
function installs non-macOS updates only, and `install/macos.sh` disables
automatic macOS upgrade downloads/restarts.

To hide major macOS upgrades from System Settings for the maximum Apple-supported
deferral window, install the local profile:

```bash
./install/defer-major-macos-upgrades.sh
```

Approve it in System Settings → Privacy & Security → Profiles. Check status with:

```bash
./install/defer-major-macos-upgrades.sh --status
```
