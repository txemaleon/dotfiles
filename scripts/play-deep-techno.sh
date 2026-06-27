#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Deep Techno
# @raycast.mode silent
# @raycast.icon 🎛️
# @raycast.packageName Music

mpv_bin="${MPV_BIN:-$(command -v mpv)}"
if [ -z "$mpv_bin" ]; then
	echo "mpv not found" >&2
	exit 1
fi

pkill mpv 2>/dev/null
nohup "$mpv_bin" --no-video --ytdl-format='bestaudio/best' "https://www.youtube.com/watch?v=G-u5OhIeln4" > /tmp/mpv.log 2>&1 &
