#!/usr/bin/env zsh

set -euo pipefail

repo_root="${0:A:h:h}"
cleanup_script="$repo_root/scripts/docker-storage-cleanup"
launch_agent="$repo_root/install/launchagents/com.txema.docker-storage-cleanup.plist"
test_root="$(mktemp -d -t docker-storage-cleanup-test)"
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

assert_not_matches() {
	local file="$1"
	local unexpected="$2"
	if grep -Fq -- "$unexpected" "$file"; then
		fail "did not expect '$unexpected' in $file"
	fi
}

run_cleanup() {
	TMPDIR="$test_root" \
		DOCKER_STORAGE_CLEANUP_PATH="$fake_bin:/usr/bin:/bin" \
		DOCKER_TEST_COMMAND_LOG="$command_log" \
		"$cleanup_script" "$@"
}

fake_bin="$test_root/bin"
command_log="$test_root/docker-commands.log"
mkdir -p "$fake_bin"

cat >"$fake_bin/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$DOCKER_TEST_COMMAND_LOG"

case "$*" in
	"context show") printf '%s\n' "${DOCKER_TEST_CONTEXT:-orbstack}" ;;
	"context inspect orbstack --format {{.Endpoints.docker.Host}}")
		[ "${DOCKER_TEST_CONTEXT_INSPECT_EXIT:-0}" = "0" ] || exit "$DOCKER_TEST_CONTEXT_INSPECT_EXIT"
		printf '%s\n' "${DOCKER_TEST_ENDPOINT:-unix://$HOME/.orbstack/run/docker.sock}"
		;;
	"info") exit "${DOCKER_TEST_INFO_EXIT:-0}" ;;
	"system df") printf '%s\n' 'TYPE TOTAL ACTIVE SIZE RECLAIMABLE' ;;
	"buildx ls --format {{json .}}")
		if [ "${DOCKER_TEST_BUILDER_INVENTORY:-valid}" = "malformed" ]; then
			printf '%s\n' 'not-json'
			exit 0
		fi
		if [ "${DOCKER_TEST_BUILDER_INVENTORY:-valid}" != "missing" ]; then
			printf '{"Name":"orbstack","Driver":"%s","Nodes":[{"Endpoint":"%s"}]}\n' \
				"${DOCKER_TEST_BUILDER_DRIVER:-docker}" \
				"${DOCKER_TEST_BUILDER_ENDPOINT:-orbstack}"
		fi
		printf '{"Name":"kamal-local-docker-container","Driver":"docker-container","Nodes":[{"Endpoint":"orbstack"}]}\n'
		printf '{"Name":"kamal-local-registry-docker-container","Driver":"docker-container","Nodes":[{"Endpoint":"orbstack"}]}\n'
		;;
	"buildx stop kamal-local-docker-container") ;;
	"buildx stop kamal-local-registry-docker-container") ;;
	"buildx prune --builder orbstack --all --force") exit "${DOCKER_TEST_PRUNE_EXIT:-0}" ;;
	"image prune --all --force") ;;
	"volume prune --force") ;;
	*)
		printf 'Unexpected fake Docker command: %s\n' "$*" >&2
		exit 99
		;;
esac
EOF
chmod +x "$fake_bin/docker"
ln -s "$(command -v jq)" "$fake_bin/jq"

run_cleanup --force >/dev/null

assert_contains "$command_log" "buildx stop kamal-local-docker-container"
assert_contains "$command_log" "buildx stop kamal-local-registry-docker-container"
assert_contains "$command_log" "buildx prune --builder orbstack --all --force"
assert_contains "$command_log" "image prune --all --force"
assert_contains "$command_log" "volume prune --force"
assert_not_matches "$command_log" "volume prune --all"
assert_not_matches "$command_log" "container prune"
assert_not_matches "$command_log" "system prune"

print "PASS: safe cleanup invokes the intended Docker operations"

: >"$command_log"
DOCKER_TEST_CONTEXT="default" run_cleanup --force >/dev/null

assert_not_matches "$command_log" "prune"
print "PASS: a non-OrbStack context is left untouched"

: >"$command_log"
DOCKER_TEST_INFO_EXIT="1" run_cleanup --force >/dev/null

assert_not_matches "$command_log" "prune"
print "PASS: a stopped Docker daemon is not started or mutated"

: >"$command_log"
run_cleanup --dry-run >/dev/null

assert_not_matches "$command_log" "buildx stop"
assert_not_matches "$command_log" "prune"
print "PASS: dry-run performs no destructive Docker operations"

: >"$command_log"
DOCKER_TEST_ENDPOINT="unix:///tmp/not-orbstack.sock" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: a spoofed OrbStack context is left untouched"

: >"$command_log"
DOCKER_TEST_BUILDER_ENDPOINT="remote" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: a builder targeting another endpoint is left untouched"

: >"$command_log"
set +e
run_cleanup >/dev/null 2>&1
missing_mode_status=$?
set -e
[[ "$missing_mode_status" == "64" ]] || fail "missing mode must exit 64"
assert_not_matches "$command_log" "prune"
print "PASS: cleanup requires an explicit execution mode"

: >"$command_log"
set +e
run_cleanup --force unexpected >/dev/null 2>&1
extra_argument_status=$?
set -e
[[ "$extra_argument_status" == "64" ]] || fail "extra arguments must exit 64"
assert_not_matches "$command_log" "prune"
print "PASS: cleanup rejects extra arguments"

: >"$command_log"
DOCKER_HOST="tcp://example.invalid:2375" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
: >"$command_log"
BUILDX_BUILDER="remote" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: Docker and Buildx environment overrides are rejected"

: >"$command_log"
DOCKER_TEST_CONTEXT_INSPECT_EXIT="1" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: an unreadable context endpoint is left untouched"

for invalid_inventory in malformed missing; do
	: >"$command_log"
	DOCKER_TEST_BUILDER_INVENTORY="$invalid_inventory" run_cleanup --force >/dev/null
	assert_not_matches "$command_log" "prune"
done
: >"$command_log"
DOCKER_TEST_BUILDER_DRIVER="docker-container" run_cleanup --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: malformed, missing, and wrong-driver builders are rejected"

no_jq_bin="$test_root/no-jq-bin"
mkdir -p "$no_jq_bin"
ln -s "$fake_bin/docker" "$no_jq_bin/docker"
ln -s /bin/date "$no_jq_bin/date"
: >"$command_log"
TMPDIR="$test_root" \
	DOCKER_STORAGE_CLEANUP_PATH="$no_jq_bin" \
	DOCKER_TEST_COMMAND_LOG="$command_log" \
	"$cleanup_script" --force >/dev/null
assert_not_matches "$command_log" "prune"
print "PASS: missing jq causes a safe skip"

no_tools_bin="$test_root/no-tools-bin"
mkdir -p "$no_tools_bin"
ln -s /bin/date "$no_tools_bin/date"
TMPDIR="$test_root" \
	DOCKER_STORAGE_CLEANUP_PATH="$no_tools_bin" \
	"$cleanup_script" --force >/dev/null
print "PASS: missing Docker causes a safe skip"

: >"$command_log"
touch "$test_root/com.txema.docker-storage-cleanup.lock"
run_cleanup --force >/dev/null
assert_contains "$command_log" "buildx prune --builder orbstack --all --force"
print "PASS: a stale lock file does not block cleanup"

: >"$command_log"
lock_file="$test_root/com.txema.docker-storage-cleanup.lock"
lockf -s -t 0 "$lock_file" sleep 10 &
lock_holder_pid=$!
lock_observed=false
for _ in {1..50}; do
	if ! lockf -s -t 0 "$lock_file" true; then
		lock_observed=true
		break
	fi
	sleep 0.01
done
$lock_observed || fail "test lock holder did not acquire the lock"
run_cleanup --force >/dev/null
kill "$lock_holder_pid" 2>/dev/null || true
wait "$lock_holder_pid" 2>/dev/null || true
assert_not_matches "$command_log" "prune"
print "PASS: concurrent cleanup is skipped"

: >"$command_log"
set +e
DOCKER_TEST_PRUNE_EXIT="1" run_cleanup --force >/dev/null 2>&1
failed_prune_status=$?
set -e
[[ "$failed_prune_status" == "1" ]] || fail "failed prune must be reported"
: >"$command_log"
run_cleanup --force >/dev/null
assert_contains "$command_log" "buildx prune --builder orbstack --all --force"
print "PASS: a failed run releases its lock for the next cleanup"

plutil -lint "$launch_agent" >/dev/null || fail "LaunchAgent plist is invalid"
[[ "$(plutil -extract StartInterval raw "$launch_agent")" == "259200" ]] ||
	fail "LaunchAgent must run every 259200 seconds"
[[ "$(plutil -extract RunAtLoad raw "$launch_agent")" == "true" ]] ||
	fail "LaunchAgent must run once when loaded"
[[ "$(plutil -extract ProgramArguments.0 raw "$launch_agent")" == "/bin/zsh" ]] ||
	fail "LaunchAgent must use the system zsh"
launch_command="$(plutil -extract ProgramArguments.2 raw "$launch_agent")"
[[ "$launch_command" == *'.local/bin/docker-storage-cleanup" --force'* ]] ||
	fail "LaunchAgent must request the explicit destructive mode"
[[ "$launch_command" != *'/Users/'* ]] ||
	fail "LaunchAgent must not hard-code a macOS username"
print "PASS: LaunchAgent runs at load and every 72 hours"
