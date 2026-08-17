#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Chillout
# @raycast.mode silent
# @raycast.icon 🌙
# @raycast.packageName Music

# Anjunachill — Chillout 24/7 radio (Sleep, Study, Meditation).
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=5oA0Ce7SW2A"
