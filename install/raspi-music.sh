#!/usr/bin/env zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
script_name="${0:t}"
source_cli="$repo_root/scripts/raspi-music"
raycast_wrappers=(
	play-house-raspi.sh
	play-deep-techno-raspi.sh
	stop-music-raspi.sh
)

usage() {
	print -u2 -- "Usage: $script_name {install|uninstall}"
}

validate_link_target() {
	local source="$1"
	local target="$2"

	if [[ -e "$target" && "$source" -ef "$target" ]]; then
		return 0
	elif [[ -L "$target" ]]; then
		[[ "$(readlink "$target")" == "$source" ]] || {
			print -u2 -- "Refusing to replace link not owned by this installer: $target"
			return 73
		}
	elif [[ -e "$target" ]]; then
		print -u2 -- "Refusing to replace existing path: $target"
		return 73
	fi
}

install_link() {
	local source="$1"
	local target="$2"

	[[ -e "$target" && "$source" -ef "$target" ]] || ln -sfn "$source" "$target"
}

install_raspi_music() {
	[[ -x "$source_cli" ]] || {
		print -u2 -- "Raspberry music CLI is missing or not executable: $source_cli"
		exit 66
	}

	local wrapper
	for wrapper in $raycast_wrappers; do
		[[ -x "$repo_root/scripts/$wrapper" ]] || {
			print -u2 -- "Raycast wrapper is missing or not executable: $repo_root/scripts/$wrapper"
			exit 66
		}
	done

	validate_link_target "$source_cli" "$HOME/.local/bin/raspi-music"
	for wrapper in $raycast_wrappers; do
		validate_link_target "$repo_root/scripts/$wrapper" "$HOME/.raycast/scripts/$wrapper"
	done

	mkdir -p "$HOME/.local/bin" "$HOME/.raycast/scripts"
	install_link "$source_cli" "$HOME/.local/bin/raspi-music"
	for wrapper in $raycast_wrappers; do
		install_link "$repo_root/scripts/$wrapper" "$HOME/.raycast/scripts/$wrapper"
	done

	print -- "Installed raspi-music for the console and Raycast."
}

remove_owned_link() {
	local source="$1"
	local target="$2"

	if [[ -e "$target" && ! -L "$target" && "$source" -ef "$target" ]]; then
		return 0
	elif [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		rm -f "$target"
	elif [[ -e "$target" || -L "$target" ]]; then
		print -u2 -- "Refusing to remove path not owned by this installer: $target"
		return 73
	fi
}

uninstall_raspi_music() {
	local wrapper

	remove_owned_link "$source_cli" "$HOME/.local/bin/raspi-music"
	for wrapper in $raycast_wrappers; do
		remove_owned_link "$repo_root/scripts/$wrapper" "$HOME/.raycast/scripts/$wrapper"
	done

	print -- "Uninstalled raspi-music console and Raycast links."
}

(( $# == 1 )) || {
	usage
	exit 64
}

case "$1" in
	install) install_raspi_music ;;
	uninstall) uninstall_raspi_music ;;
	*)
		usage
		exit 64
		;;
esac
