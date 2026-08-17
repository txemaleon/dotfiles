#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Trance
# @raycast.mode silent
# @raycast.icon ✨
# @raycast.packageName Music

# Anjunabeats Radio — Live 24/7 Trance & Progressive (Above & Beyond).
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=IvuwTft-0cM"
