#!/bin/bash
# Shared player for the Music Raycast scripts (play-*.sh).
# Each station script sources this file and calls:  radio_play <youtube-url>
#
# Why a wrapper at all: YouTube live HLS returns 403 once its CDN token rotates
# after a few minutes (known mpv/ffmpeg bug, mpv#16594 / #16563). A lone mpv
# can't re-resolve the stream and freezes. Two layers keep a station alive 24/7:
#
#   1. Auto-restart loop  — if mpv EXITS, wait 2s and relaunch; yt-dlp then
#                           re-resolves a fresh manifest/CDN host.
#   2. Stuck-clock watchdog — if mpv stays ALIVE but its playback clock stops
#                           advancing (~30s), kill it so the loop re-resolves.
#
# Both run under a `bash -c` whose argv carries the RADIO_RESTART_LOOP marker,
# so starting any station can stop the previous one with `pkill -f`.
# A parallel test on 2026-08-18 measured 11 restarts in 10 minutes with
# yt-dlp's default client and none with Android, so playback pins Android.

radio_play() {
	local url="$1"
	local mpv_bin="${MPV_BIN:-$(command -v mpv)}"
	if [ -z "$mpv_bin" ]; then
		echo "mpv not found" >&2
		return 1
	fi

	# Stop the previous wrapper (loop + watchdog) FIRST, then mpv itself, so
	# switching stations never leaves anything respawning the old stream.
	pkill -f RADIO_RESTART_LOOP 2>/dev/null
	pkill -x mpv 2>/dev/null
	local _
	for _ in {1..20}; do
		pgrep -x mpv >/dev/null || break
		sleep 0.1
	done
	pkill -9 -f RADIO_RESTART_LOOP 2>/dev/null
	pkill -9 -x mpv 2>/dev/null

	nohup bash -c '
		# RADIO_RESTART_LOOP
		log=/tmp/mpv.log

		# Watchdog: mpv prints a playback position as "A: h:mm:ss" in its status
		# line. On a healthy live stream it advances every second; when YouTube
		# rotates its CDN token the position freezes (403 skip-buffering loop)
		# and mpv does NOT exit on its own. So we poll every 2s and, after ~6s
		# with no progress, kill mpv -> the loop below re-resolves a fresh host.
		# Fast on purpose: this gap IS the audible cut, so we minimise it.
		(
			last=""; stuck=0
			while true; do
				sleep 2
				cur=$(grep -oE "A: [0-9:]+" "$log" 2>/dev/null | tail -1)
				if [ -n "$cur" ] && [ "$cur" = "$last" ]; then
					stuck=$((stuck + 1))
					[ "$stuck" -ge 3 ] && { pkill -x mpv 2>/dev/null; stuck=0; }
				else
					stuck=0
				fi
				last="$cur"
			done
		) &

		# Auto-restart loop.
		while true; do
			"$1" --no-video --ytdl-format=bestaudio/best \
				--ytdl-raw-options="extractor-args=youtube:player_client=android" \
				--cache=yes --demuxer-max-bytes=64MiB "$2" >"$log" 2>&1
			sleep 1
		done
	' _ "$mpv_bin" "$url" >/dev/null 2>&1 &
}
