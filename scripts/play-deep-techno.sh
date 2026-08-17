#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Deep Techno
# @raycast.mode silent
# @raycast.icon 🎛️
# @raycast.packageName Music

# Bassport Music — Deep Techno 24/7 live stream.
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=G-u5OhIeln4"
