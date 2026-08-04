#!/usr/bin/env zsh

set -euo pipefail

repo_root="${0:A:h:h}"
music_cli="$repo_root/scripts/raspi-music"
test_root="$(mktemp -d -t raspi-music-test)"
trap 'rm -rf "$test_root"' EXIT

fail() {
	print -u2 -- "FAIL: $1"
	exit 1
}

assert_contains() {
	local file="$1"
	local expected="$2"
	grep -Fqx -- "$expected" "$file" || fail "expected '$expected' in $file"
}

fake_bin="$test_root/bin"
ssh_args_log="$test_root/ssh-args.log"
ssh_stdin_log="$test_root/ssh-stdin.log"
mkdir -p "$fake_bin"

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
: "${SSH_TEST_ARGS_LOG:?}"
: "${SSH_TEST_STDIN_LOG:?}"
printf '%s\n' "$@" >"$SSH_TEST_ARGS_LOG"
cat >"$SSH_TEST_STDIN_LOG"
printf '%s\n' "${SSH_TEST_OUTPUT:-Started Raspberry playback.}"
exit "${SSH_TEST_EXIT:-0}"
EOF
chmod +x "$fake_bin/ssh"

url='https://music.youtube.com/watch?v=track-id&list=playlist-id'
output="$({
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
		SSH_TEST_ARGS_LOG="$ssh_args_log" \
		SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
		"$music_cli" play "$url"
} 2>&1)"

[[ "$output" == "Started Raspberry playback." ]] || fail "unexpected play output: $output"
assert_contains "$ssh_args_log" "BatchMode=yes"
assert_contains "$ssh_args_log" "ConnectTimeout=5"
assert_contains "$ssh_args_log" "raspi"
[[ "$(<"$ssh_stdin_log")" == "$url" ]] || fail "play URL was not passed intact over standard input"
grep -Fq -- "$url" "$ssh_args_log" && fail "play URL was interpolated into the remote shell command"

print "PASS: play sends an intact URL to the non-interactive raspi SSH target"

rm -f "$ssh_args_log" "$ssh_stdin_log"
set +e
invalid_output="$({
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
		SSH_TEST_ARGS_LOG="$ssh_args_log" \
		SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
		"$music_cli" play '/tmp/local-audio.mp3'
} 2>&1)"
invalid_status=$?
set -e

[[ "$invalid_status" == "64" ]] || fail "invalid URL must exit 64, got $invalid_status"
[[ "$invalid_output" == *"URL must start with http:// or https://."* ]] ||
	fail "invalid URL did not explain the accepted schemes"
[[ ! -e "$ssh_args_log" ]] || fail "invalid URL opened an SSH connection"

print "PASS: invalid play input is rejected without contacting the Raspberry"

rm -f "$ssh_args_log" "$ssh_stdin_log"
set +e
multiline_output="$({
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
		SSH_TEST_ARGS_LOG="$ssh_args_log" \
		SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
		"$music_cli" play $'https://youtube.com/watch?v=track\nsecond-line'
} 2>&1)"
multiline_status=$?
set -e

[[ "$multiline_status" == "64" ]] || fail "multiline URL must exit 64, got $multiline_status"
[[ "$multiline_output" == *"URL must be a single line."* ]] ||
	fail "multiline URL did not explain the single-line requirement"
[[ ! -e "$ssh_args_log" ]] || fail "multiline URL opened an SSH connection"

print "PASS: multiline URLs are rejected without contacting the Raspberry"

SSH_TEST_OUTPUT="Stopped Raspberry playback." \
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
	SSH_TEST_ARGS_LOG="$ssh_args_log" \
	SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
	"$music_cli" stop >"$test_root/stop-output"

[[ "$(<"$test_root/stop-output")" == "Stopped Raspberry playback." ]] ||
	fail "unexpected stop output"
grep -Fq -- "pkill -x mpv" "$ssh_args_log" || fail "stop did not request graceful remote termination"
grep -Fq -- "pkill -KILL -x mpv" "$ssh_args_log" || fail "stop did not include the bounded force-kill fallback"
grep -Fq -- "nohup mpv" "$ssh_args_log" && fail "stop attempted to start playback"

print "PASS: stop performs the bounded remote mpv shutdown"

SSH_TEST_OUTPUT=$'playing\n912 mpv https://music.youtube.com/watch?v=track-id' \
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
	SSH_TEST_ARGS_LOG="$ssh_args_log" \
	SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
	"$music_cli" status >"$test_root/status-output"

[[ "$(<"$test_root/status-output")" == $'playing\n912 mpv https://music.youtube.com/watch?v=track-id' ]] ||
	fail "unexpected status output"
grep -Fq -- "pgrep -a -x mpv" "$ssh_args_log" || fail "status did not inspect the remote mpv process"
grep -Fq -- "pkill" "$ssh_args_log" && fail "status attempted to stop playback"
grep -Fq -- "nohup" "$ssh_args_log" && fail "status attempted to start playback"

print "PASS: status inspects playback without changing it"

SSH_TEST_OUTPUT='audio stream opened' \
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
	SSH_TEST_ARGS_LOG="$ssh_args_log" \
	SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
	"$music_cli" logs >"$test_root/logs-output"

[[ "$(<"$test_root/logs-output")" == "audio stream opened" ]] || fail "unexpected logs output"
grep -Fq -- "tail -n 100 /tmp/mpv.log" "$ssh_args_log" || fail "logs did not read the bounded remote log tail"
grep -Fq -- "pkill" "$ssh_args_log" && fail "logs attempted to stop playback"
grep -Fq -- "nohup" "$ssh_args_log" && fail "logs attempted to start playback"

print "PASS: logs reads a bounded remote diagnostic tail without changing playback"

set +e
SSH_TEST_OUTPUT='ssh unavailable' \
	SSH_TEST_EXIT=255 \
	RASPI_MUSIC_PATH="$fake_bin:/usr/bin:/bin" \
	SSH_TEST_ARGS_LOG="$ssh_args_log" \
	SSH_TEST_STDIN_LOG="$ssh_stdin_log" \
	"$music_cli" status >"$test_root/ssh-failure-output" 2>&1
ssh_failure_status=$?
set -e

[[ "$ssh_failure_status" == "255" ]] || fail "SSH failure must be propagated, got $ssh_failure_status"
[[ "$(<"$test_root/ssh-failure-output")" == "ssh unavailable" ]] ||
	fail "SSH failure output was hidden or rewritten"

print "PASS: SSH failures are returned to console callers"
