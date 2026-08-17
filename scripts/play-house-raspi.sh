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

# Spinnin' Records — official 24/7 live radio, energetic house/EDM. Replaces
# D4MdHQOILdw, which YouTube removed; same station as play-house.sh on macOS.
exec "$raspi_music_bin" play "https://www.youtube.com/watch?v=xf9Ejt4OmWQ"
