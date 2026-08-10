#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Play House
# @raycast.mode silent
# @raycast.icon 🎶
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

# NOTE: original repo URL (D4MdHQOILdw) went dead — YouTube removed that stream.
# Anjunadeep has no 24/7 live house radio, so this points at their official
# "Anjunadeep Essentials" continuous DJ mix on infinite loop. Set 2026-08-10.
nohup "$mpv_bin" --no-video --loop=inf --ytdl-format='bestaudio/best' "https://www.youtube.com/watch?v=RhRUVQTOshE" > /tmp/mpv.log 2>&1 &
