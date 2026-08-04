#!/usr/bin/env zsh

set -euo pipefail

repo_root="${0:A:h:h}"
test_root="$(mktemp -d -t raspi-music-raycast-test)"
trap 'rm -rf "$test_root"' EXIT

fail() {
	print -u2 -- "FAIL: $1"
	exit 1
}

fake_cli="$test_root/raspi-music"
arguments_log="$test_root/arguments.log"

cat >"$fake_cli" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$RASPI_MUSIC_WRAPPER_ARGS_LOG"
EOF
chmod +x "$fake_cli"

RASPI_MUSIC_BIN="$fake_cli" \
	RASPI_MUSIC_WRAPPER_ARGS_LOG="$arguments_log" \
	"$repo_root/scripts/play-house-raspi.sh"

expected=$'play\nhttps://www.youtube.com/watch?v=D4MdHQOILdw'
[[ "$(<"$arguments_log")" == "$expected" ]] || fail "House wrapper delegated unexpected arguments"

print "PASS: the House Raycast command delegates its URL to raspi-music"

RASPI_MUSIC_BIN="$fake_cli" \
	RASPI_MUSIC_WRAPPER_ARGS_LOG="$arguments_log" \
	"$repo_root/scripts/play-deep-techno-raspi.sh"

expected=$'play\nhttps://www.youtube.com/watch?v=G-u5OhIeln4'
[[ "$(<"$arguments_log")" == "$expected" ]] || fail "Deep Techno wrapper delegated unexpected arguments"

print "PASS: the Deep Techno Raycast command delegates its URL to raspi-music"

RASPI_MUSIC_BIN="$fake_cli" \
	RASPI_MUSIC_WRAPPER_ARGS_LOG="$arguments_log" \
	"$repo_root/scripts/stop-music-raspi.sh"

[[ "$(<"$arguments_log")" == "stop" ]] || fail "Stop wrapper delegated unexpected arguments"

print "PASS: the Stop Raycast command delegates to raspi-music"
