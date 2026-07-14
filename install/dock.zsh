#!/usr/bin/env zsh

# Shared dock layout — sourced by macos.sh and functions/updates

function configure_dock() {
	local list="${1:-${DOTFILES:-$HOME/.config/dotfiles}/install/lists/dock-apps.list}"
	local -a apps=()
	local app expanded

	if [[ ! -f "$list" ]]; then
		print -u2 "Dock layout not applied: app list not found at $list"
		return 1
	fi
	if ! command -v dockutil &>/dev/null; then
		print -u2 "Dock layout not applied: dockutil is not installed"
		return 1
	fi

	while IFS= read -r app; do
		[[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
		expanded="${app/#\~/$HOME}"
		if [[ ! -e "$expanded" ]]; then
			print -u2 "Dock layout not applied: entry not found at $expanded"
			return 1
		fi
		apps+=("$app")
	done <"$list"

	if (( ${#apps[@]} == 0 )); then
		print -u2 "Dock layout not applied: app list is empty"
		return 1
	fi

	dockutil --remove all --no-restart || return 1
	for app in "${apps[@]}"; do
		if ! dockutil --add "$app" --no-restart; then
			print -u2 "Dock layout incomplete: failed to add $app"
			killall Dock &>/dev/null || true
			return 1
		fi
	done

	if ! killall Dock &>/dev/null; then
		print -u2 "Dock layout saved, but the Dock could not be restarted"
		return 1
	fi
}
