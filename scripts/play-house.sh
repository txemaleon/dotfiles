#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play House
# @raycast.mode silent
# @raycast.icon 🎶
# @raycast.packageName Music

# Spinnin' Records — official 24/7 live radio, energetic house/EDM
# (big room, future & club house). The main, higher-energy house stream.
source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"
radio_play "https://www.youtube.com/watch?v=xf9Ejt4OmWQ"
