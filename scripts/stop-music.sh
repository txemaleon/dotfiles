#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Stop Music
# @raycast.mode silent
# @raycast.icon ⏹️
# @raycast.packageName Music

# Stop the auto-restart wrapper (loop + watchdog) FIRST, or it respawns mpv.
pkill -f RADIO_RESTART_LOOP 2>/dev/null
pkill -x mpv 2>/dev/null
for _ in {1..20}; do
	pgrep -x mpv >/dev/null || break
	sleep 0.1
done
pkill -9 -f RADIO_RESTART_LOOP 2>/dev/null
pkill -9 -x mpv 2>/dev/null

exit 0
