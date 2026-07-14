#!/usr/bin/env zsh

set -euo pipefail
trap 'echo "❌ installer.sh failed at line $LINENO (exit $?)" >&2' ERR

if [[ "$OSTYPE" != darwin* ]]; then
	echo "⚠️  This installer targets macOS. Detected: $OSTYPE" >&2
	echo "   Linux/other support is not implemented. Aborting." >&2
	exit 1
fi

# Paths
SCRIPT_ABS_PATH="${0:A}"                 # Absolute path to the script itself
SCRIPT_DIR=$(dirname "$SCRIPT_ABS_PATH") # Absolute path to the install directory
PARENT_DIR=$(dirname "$SCRIPT_DIR")      # Absolute path to the dotfiles root directory
INSTALL_DIR="$SCRIPT_DIR"                # Use absolute path for install dir too
DOTFILES_CONFIG_DIR="$PARENT_DIR/config" # Absolute path to config dir
DOTFILES_SCRIPTS_DIR="$PARENT_DIR/scripts"
ICLOUD_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_CONFIG="$ICLOUD_PATH/config"
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

link_mackup_config() {
	if [ -f "$INSTALL_DIR/mackup.cfg" ]; then
		ln -sf "$INSTALL_DIR/mackup.cfg" ~/.mackup.cfg
	fi
	if [ -d "$INSTALL_DIR/mackup" ]; then
		mkdir -p ~/.mackup
		for _mackup_cfg in "$INSTALL_DIR/mackup"/*.cfg(.N); do
			ln -sf "$_mackup_cfg" "$HOME/.mackup/${_mackup_cfg:t}"
		done
		unset _mackup_cfg
	fi
}

install_launchagents() {
	local agents_dir="$INSTALL_DIR/launchagents"
	[[ -d "$agents_dir" ]] || return 0

	mkdir -p "$HOME/Library/LaunchAgents"
	for agent in "$agents_dir"/*.plist(.N); do
		local target="$HOME/Library/LaunchAgents/${agent:t}"
		ln -sf "$agent" "$target"
		launchctl bootout "gui/$(id -u)" "$target" >/dev/null 2>&1 || true
		launchctl bootstrap "gui/$(id -u)" "$target" >/dev/null 2>&1 || true
		launchctl enable "gui/$(id -u)/${agent:t:r}" >/dev/null 2>&1 || true
		launchctl kickstart -k "gui/$(id -u)/${agent:t:r}" >/dev/null 2>&1 || true
	done
	unset agent
}

install_launchdaemons() {
	local daemons_dir="$INSTALL_DIR/launchdaemons"
	[[ -d "$daemons_dir" ]] || return 0

	if [[ -x "$INSTALL_DIR/support/raycast-priority" ]]; then
		sudo mkdir -p /usr/local/bin
		sudo cp "$INSTALL_DIR/support/raycast-priority" /usr/local/bin/raycast-priority
		sudo chown root:wheel /usr/local/bin/raycast-priority
		sudo chmod 755 /usr/local/bin/raycast-priority
	fi
	if [[ -x "$INSTALL_DIR/support/codex-priority" ]]; then
		sudo mkdir -p /usr/local/bin
		sudo cp "$INSTALL_DIR/support/codex-priority" /usr/local/bin/codex-priority
		sudo chown root:wheel /usr/local/bin/codex-priority
		sudo chmod 755 /usr/local/bin/codex-priority
	fi

	for daemon in "$daemons_dir"/*.plist(.N); do
		local target="/Library/LaunchDaemons/${daemon:t}"
		echo "Installing LaunchDaemon ${daemon:t}"
		sudo cp "$daemon" "$target"
		sudo chown root:wheel "$target"
		sudo chmod 644 "$target"
		sudo launchctl bootout system "$target" >/dev/null 2>&1 || true
		sudo launchctl bootstrap system "$target" >/dev/null 2>&1 || true
		sudo launchctl enable "system/${daemon:t:r}" >/dev/null 2>&1 || true
		sudo launchctl kickstart -k "system/${daemon:t:r}" >/dev/null 2>&1 || true
	done
	unset daemon
}

check_karabiner_setup() {
	local cli="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
	[[ -x "$cli" ]] || return 0

	local guidance
	guidance="$("$cli" --show-settings-window-guidance 2>/dev/null || true)"
	[[ -n "$guidance" ]] || return 0

	if echo "$guidance" | grep -q '"driver_activated": false\|"accessibility_process_trusted": false\|"iohid_listen_event_allowed": false'; then
		echo "⚠️  Karabiner needs macOS approval before keyboard mappings work."
		echo "   Open Karabiner-Elements and approve Accessibility, Input Monitoring, and the VirtualHID system extension in System Settings."
		open -a "Karabiner-Elements" 2>/dev/null || true
		"$cli" --show-settings-window-guidance || true
	fi
}

SUDO_KEEPALIVE_PID=""
start_sudo_keepalive() {
	sudo -v
	while true; do
		sudo -n true
		sleep 60
		kill -0 "$$" || exit
	done 2>/dev/null &
	SUDO_KEEPALIVE_PID="$!"
}

stop_sudo_keepalive() {
	if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
		kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
	fi
}
trap stop_sudo_keepalive EXIT

validate_layout() {
	if [ ! -d "$DOTFILES_CONFIG_DIR" ] || [ ! -f "$INSTALL_DIR/Brewfile" ] || [ ! -f "$INSTALL_DIR/Bunfile" ] || [ ! -f "$INSTALL_DIR/macos.sh" ] || [ ! -f "$INSTALL_DIR/gitconfig.sh" ]; then
		echo "Error: Required files or directories not found."
		echo "Ensure Brewfile, Bunfile, macos.sh, gitconfig.sh are in $INSTALL_DIR"
		echo "Ensure the config directory exists at $DOTFILES_CONFIG_DIR"
		echo "Please consider running this script from the dotfiles root directory: $PARENT_DIR"
		exit 1
	fi
}

install_dotfiles() {
	for FILE in $DOTFILES_CONFIG_DIR/*; do
		f=$(basename $FILE)
		TARGET_FILE="$HOME/.$f"
		if [ -L "$TARGET_FILE" ] || [ -f "$TARGET_FILE" ]; then
			rm -rf "$TARGET_FILE"
		fi
		echo "Linking $FILE => $TARGET_FILE"
		ln -s "$FILE" "$TARGET_FILE"
	done
}

install_raycast_scripts() {
	[[ -d "$DOTFILES_SCRIPTS_DIR" ]] || return 0

	mkdir -p "$HOME/.raycast/scripts"
	for script in "$DOTFILES_SCRIPTS_DIR"/*(.N); do
		grep -q "^# @raycast.schemaVersion " "$script" || continue
		local target="$HOME/.raycast/scripts/${script:t}"
		if [[ -e "$target" && ! -L "$target" ]]; then
			rm -f "$target"
		fi
		echo "Linking $script => $target"
		ln -sf "$script" "$target"
		chmod +x "$script"
	done
	unset script
}

install_homebrew() {
	if ! command -v brew &>/dev/null; then
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	else
		echo "Homebrew already installed."
	fi
}

cleanup_packages() {
	if [[ "${DOTFILES_CLEANUP:-true}" == "true" && -x "$INSTALL_DIR/cleanup.sh" ]]; then
		echo "Cleaning packages not listed in Brewfile/Bunfile..."
		"$INSTALL_DIR/cleanup.sh"
	else
		echo "Skipping cleanup. Set DOTFILES_CLEANUP=true to enable it."
	fi
}

install_brew_packages() {
	echo "Installing Brewfile packages..."
	brew bundle --file="$INSTALL_DIR/Brewfile"
}

restore_mackup() {
	link_mackup_config
	if [ -d "$ICLOUD_CONFIG" ]; then
		if command -v mackup &>/dev/null; then
			echo "Restoring app configs from iCloud (mackup)..."

			# Restore copies from iCloud (not symlinks — avoids sync issues)
			mackup restore --force
			link_mackup_config
		else
			echo "mackup not installed, skipping app config restore"
		fi
	else
		echo "⚠️  iCloud not configured, skipping mackup restore"
	fi
}

install_node_tools() {
	echo "Installing global bun packages from $INSTALL_DIR/Bunfile..."
	if [ -f "$INSTALL_DIR/Bunfile" ]; then
		NPM_PACKAGES=$(sed 's/#.*//' "$INSTALL_DIR/Bunfile" | grep -v '^[[:space:]]*$' || true)
		if [ -n "$NPM_PACKAGES" ]; then
			echo "$NPM_PACKAGES" | xargs bun add -g
		else
			echo "No packages found in Bunfile."
		fi
	else
		echo "Warning: Bunfile not found at $INSTALL_DIR/Bunfile"
	fi
}

configure_git() {
	if [ -f "$INSTALL_DIR/gitconfig.sh" ]; then
		echo "Running git configuration script..."
		sh "$INSTALL_DIR/gitconfig.sh"
	else
		echo "Warning: gitconfig.sh not found at $INSTALL_DIR/gitconfig.sh"
	fi
}

configure_macos() {
	if [[ "${DOTFILES_APPLY_MACOS:-false}" == "true" && -f "$INSTALL_DIR/macos.sh" ]]; then
		echo "Applying macOS settings..."
		if [[ "${DOTFILES_MACOS_PRIVILEGED:-false}" == "true" ]]; then
			start_sudo_keepalive
		fi
		source "$INSTALL_DIR/macos.sh"
		stop_sudo_keepalive
	elif [[ "${DOTFILES_APPLY_MACOS:-false}" != "true" ]]; then
		echo "Skipping macOS settings. Set DOTFILES_APPLY_MACOS=true to apply them."
	else
		echo "Warning: macos.sh not found at $INSTALL_DIR/macos.sh"
	fi
}

install_zinit() {
	if [ ! -d "$ZINIT_HOME" ]; then
		echo "Installing zinit plugin manager..."
		mkdir -p "$(dirname $ZINIT_HOME)"
		git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
	else
		echo "zinit already installed."
	fi
}

show_upgrade_deferral_status() {
	if [ -x "$INSTALL_DIR/defer-major-macos-upgrades.sh" ]; then
		"$INSTALL_DIR/defer-major-macos-upgrades.sh" --status || true
		echo "Run $INSTALL_DIR/defer-major-macos-upgrades.sh to hide major macOS upgrades in System Settings."
	fi
}

validate_layout
install_dotfiles
install_raycast_scripts
install_homebrew
cleanup_packages
install_brew_packages
restore_mackup
check_karabiner_setup
install_launchagents
install_launchdaemons
install_node_tools
configure_git
configure_macos
install_zinit
show_upgrade_deferral_status

echo "Installation complete."
echo "Note: Plugins will auto-install on first shell startup via zinit."
