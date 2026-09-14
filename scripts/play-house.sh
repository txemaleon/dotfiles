#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play House
# @raycast.mode silent
# @raycast.icon 🎶
# @raycast.packageName Music

# Anjunadeep Radio — official 24/7 live stream from the Anjunadeep label
# ("Best of Deep House, Chill, House, Progressive"). Melodic and laid-back,
# not the big-room/EDM kind of house.
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=AkZuqGvcLME"
