#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Chill House
# @raycast.mode silent
# @raycast.icon 🛋️
# @raycast.packageName Music

# The Good Life Radio x Sensual Musique — live 24/7, biggest house stream by
# audience (~2200 listeners). Chill / deep house (the mellow "chill house").
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=36YnV9STBqc"
