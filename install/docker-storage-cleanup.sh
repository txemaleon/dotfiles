#!/usr/bin/env zsh

set -euo pipefail

label="com.txema.docker-storage-cleanup"
script_name="${0:t}"
script_dir="${0:A:h}"
repo_root="${script_dir:h}"
source_script="$repo_root/scripts/docker-storage-cleanup"
source_agent="$script_dir/launchagents/$label.plist"
installed_script="$HOME/.local/bin/docker-storage-cleanup"
installed_agent="$HOME/Library/LaunchAgents/$label.plist"
user_domain="gui/$(id -u)"

usage() {
	print -- "Usage: $script_name {install|status|uninstall}"
}

validate_link_target() {
	local source="$1"
	local target="$2"

	if [[ -L "$target" ]]; then
		if [[ "$(readlink "$target")" != "$source" ]]; then
			print -u2 -- "Refusing to replace symlink not owned by this installer: $target"
			return 73
		fi
	elif [[ -e "$target" ]]; then
		print -u2 -- "Refusing to replace non-symlink path: $target"
		return 73
	fi
}

install_link() {
	local source="$1"
	local target="$2"

	ln -sfn "$source" "$target"
}

install_cleanup() {
	[[ "$OSTYPE" == darwin* ]] || {
		print -u2 -- "Docker storage cleanup installation requires macOS."
		exit 69
	}
	[[ -x "$source_script" ]] || {
		print -u2 -- "Cleanup executable is missing or not executable: $source_script"
		exit 66
	}
	plutil -lint "$source_agent" >/dev/null
	validate_link_target "$source_script" "$installed_script"
	validate_link_target "$source_agent" "$installed_agent"

	mkdir -p "${installed_script:h}" "${installed_agent:h}" "$HOME/Library/Logs"
	install_link "$source_script" "$installed_script"
	install_link "$source_agent" "$installed_agent"

	launchctl bootout "$user_domain" "$installed_agent" >/dev/null 2>&1 || true
	launchctl bootstrap "$user_domain" "$installed_agent"
	launchctl enable "$user_domain/$label"
	launchctl print "$user_domain/$label" >/dev/null

	print -- "Installed $label (runs at load and every 72 hours)."
}

show_status() {
	launchctl print "$user_domain/$label"
}

remove_owned_link() {
	local source="$1"
	local target="$2"

	if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		rm -f "$target"
	elif [[ -e "$target" || -L "$target" ]]; then
		print -u2 -- "Refusing to remove path not owned by this installer: $target"
		return 73
	fi
}

uninstall_cleanup() {
	launchctl bootout "$user_domain" "$installed_agent" >/dev/null 2>&1 || true
	remove_owned_link "$source_agent" "$installed_agent"
	remove_owned_link "$source_script" "$installed_script"
	print -- "Uninstalled $label. Existing log files were preserved."
}

(( $# == 1 )) || {
	usage >&2
	exit 64
}

case "$1" in
	install) install_cleanup ;;
	status) show_status ;;
	uninstall) uninstall_cleanup ;;
	*)
		usage >&2
		exit 64
		;;
esac
