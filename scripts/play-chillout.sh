#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play Chillout
# @raycast.mode silent
# @raycast.icon 🌙
# @raycast.packageName Music

mpv_bin="${MPV_BIN:-$(command -v mpv)}"
if [ -z "$mpv_bin" ]; then
	echo "mpv not found" >&2
	exit 1
fi

pkill -x mpv 2>/dev/null
for _ in {1..20}; do
	pgrep -x mpv >/dev/null || break
	sleep 0.1
done
pkill -9 -x mpv 2>/dev/null

# Anjunachill — Chillout 24/7 radio (Sleep, Study, Meditation). Set 2026-08-10.
nohup "$mpv_bin" --no-video --ytdl-format='bestaudio/best' "https://www.youtube.com/watch?v=5oA0Ce7SW2A" > /tmp/mpv.log 2>&1 &
