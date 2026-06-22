#!/usr/bin/env zsh

# Shared dock layout — sourced by macos.sh and functions/updates

function configure_dock() {
	local list="${1:-${DOTFILES:-$HOME/.config/dotfiles}/install/lists/dock-apps.list}"

	[[ -f "$list" ]] || return 0
	command -v dockutil &>/dev/null || return 0

	dockutil -r all
	while IFS= read -r app; do
		[[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
		dockutil -a "$app" 2>/dev/null || true
	done <"$list"
	killall Dock &>/dev/null || true
}
