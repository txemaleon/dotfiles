#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Proton
# @raycast.mode silent
# @raycast.icon 🪐
# @raycast.packageName Music

# Proton Radio — progressive house / melodic techno, the label's own shows.
#
# Unlike the other stations this is NOT a live stream, because Proton no longer
# has one anywhere (all checked 2026-09-11):
#   - https://api.protonradio.com/api/v2/radio/now_playing answers
#     {"success":false,"message":"The radio stream is gone. Please go to YouTube."}
#   - shoutcast.protonradio.com / icecast.protonradio.com, still hardcoded in
#     their own web player, no longer resolve in DNS.
#   - The @protonradio YouTube channel has no live and no streams tab, and a
#     live-filtered YouTube search returns nothing of theirs.
#
# So this plays their "Latest Radio Shows" playlist shuffled: 766 recent shows,
# roughly an hour each, back to back. That playlist is the channel's own curated
# feed of new episodes, which is why it is used instead of the uploads playlist —
# YouTube serves the uploads in a scrambled order that mixes 2011 into 2026.
# It enumerates in ~5s, so there is no playlist-end cap; --shuffle randomises all
# 766, and when they run out mpv exits and the restart loop reshuffles.
#
# Each track change needs a fresh yt-dlp resolve, which to the stuck-clock
# watchdog looks identical to a frozen stream — hence the longer fuse: 8 polls
# x 2s = ~16s of no progress before it decides mpv is really stuck.

source "$(dirname "$(readlink -f "$0")")/radio-lib.sh"

RADIO_STUCK_POLLS=8
radio_play "https://www.youtube.com/playlist?list=PLd0gkRUzUOD3NYv182omsbpKTYEFC_ejO" --shuffle
