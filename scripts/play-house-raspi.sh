#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play House on Raspberry
# @raycast.mode silent
# @raycast.icon 🎶
# @raycast.packageName Raspberry Music

set -euo pipefail

raspi_music_bin="${RASPI_MUSIC_BIN:-$HOME/.local/bin/raspi-music}"

[[ -x "$raspi_music_bin" ]] || {
	echo "raspi-music is not installed at $raspi_music_bin" >&2
	exit 69
}

exec "$raspi_music_bin" play "https://www.youtube.com/watch?v=D4MdHQOILdw"
