#!/usr/bin/env zsh

set -euo pipefail

repo_root="${0:A:h:h}"
installer="$repo_root/install/raspi-music.sh"
test_root="$(mktemp -d -t raspi-music-install-test)"
trap 'rm -rf "$test_root"' EXIT

fail() {
	print -u2 -- "FAIL: $1"
	exit 1
}

fake_home="$test_root/home"
mkdir -p "$fake_home"

HOME="$fake_home" "$installer" install >/dev/null

cli_link="$fake_home/.local/bin/raspi-music"
[[ -L "$cli_link" ]] || fail "console command was not linked"
[[ "$(readlink "$cli_link")" == "$repo_root/scripts/raspi-music" ]] ||
	fail "console command points to the wrong executable"

for wrapper in play-house-raspi.sh play-deep-techno-raspi.sh stop-music-raspi.sh; do
	link="$fake_home/.raycast/scripts/$wrapper"
	[[ -L "$link" ]] || fail "$wrapper was not linked for Raycast"
	[[ "$(readlink "$link")" == "$repo_root/scripts/$wrapper" ]] ||
		fail "$wrapper points to the wrong Raycast script"
done

print "PASS: install exposes raspi-music in the console and the new Raspberry commands in Raycast"

HOME="$fake_home" "$installer" install >/dev/null
[[ "$(readlink "$cli_link")" == "$repo_root/scripts/raspi-music" ]] ||
	fail "reinstall changed the console link"
print "PASS: installation is idempotent"

foreign_home="$test_root/foreign-home"
foreign_target="$test_root/foreign-command"
mkdir -p "$foreign_home/.local/bin"
touch "$foreign_target"
ln -s "$foreign_target" "$foreign_home/.local/bin/raspi-music"

set +e
HOME="$foreign_home" "$installer" install >/dev/null 2>&1
foreign_status=$?
set -e

[[ "$foreign_status" == "73" ]] || fail "foreign console link must exit 73, got $foreign_status"
[[ "$(readlink "$foreign_home/.local/bin/raspi-music")" == "$foreign_target" ]] ||
	fail "installer replaced a foreign console link"
[[ ! -d "$foreign_home/.raycast" ]] || fail "console conflict caused a partial Raycast installation"

print "PASS: installation preserves foreign links without partial changes"

linked_raycast_home="$test_root/linked-raycast-home"
mkdir -p "$linked_raycast_home/.raycast"
ln -s "$repo_root/scripts" "$linked_raycast_home/.raycast/scripts"
HOME="$linked_raycast_home" "$installer" install >/dev/null
[[ -L "$linked_raycast_home/.local/bin/raspi-music" ]] ||
	fail "linked Raycast directory prevented console installation"
[[ -L "$linked_raycast_home/.raycast/scripts" ]] ||
	fail "installer replaced the existing Raycast directory link"
[[ "$(readlink "$linked_raycast_home/.raycast/scripts")" == "$repo_root/scripts" ]] ||
	fail "installer changed the existing Raycast directory link"

print "PASS: install accepts Raycast targets that already resolve to the source files"

HOME="$linked_raycast_home" "$installer" uninstall >/dev/null
[[ ! -e "$linked_raycast_home/.local/bin/raspi-music" &&
	! -L "$linked_raycast_home/.local/bin/raspi-music" ]] ||
	fail "linked-directory uninstall left the console link behind"
[[ -L "$linked_raycast_home/.raycast/scripts" ]] ||
	fail "uninstall removed the pre-existing Raycast directory link"
for wrapper in play-house-raspi.sh play-deep-techno-raspi.sh stop-music-raspi.sh; do
	[[ -x "$repo_root/scripts/$wrapper" ]] || fail "uninstall deleted source wrapper $wrapper"
done

print "PASS: uninstall preserves wrappers exposed through a pre-existing directory link"

HOME="$fake_home" "$installer" uninstall >/dev/null
[[ ! -e "$cli_link" && ! -L "$cli_link" ]] || fail "uninstall left the console link behind"
for wrapper in play-house-raspi.sh play-deep-techno-raspi.sh stop-music-raspi.sh; do
	link="$fake_home/.raycast/scripts/$wrapper"
	[[ ! -e "$link" && ! -L "$link" ]] || fail "uninstall left $wrapper behind"
done

print "PASS: uninstall removes only the Raspberry music links"
