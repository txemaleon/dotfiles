#!/usr/bin/env zsh

set -euo pipefail

repo_root="${0:A:h:h}"
installer="$repo_root/install/docker-storage-cleanup.sh"
workstation_installer="$repo_root/install/installer.sh"
workstation_uninstaller="$repo_root/install/uninstall.sh"
cleanup_script="$repo_root/scripts/docker-storage-cleanup"
source_agent="$repo_root/install/launchagents/com.txema.docker-storage-cleanup.plist"
test_root="$(mktemp -d -t docker-storage-cleanup-install-test)"
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

fake_home="$test_root/home"
fake_bin="$test_root/bin"
launchctl_log="$test_root/launchctl.log"
mkdir -p "$fake_home" "$fake_bin"

cat >"$fake_bin/launchctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$LAUNCHCTL_TEST_LOG"
if [ "$1" = "bootstrap" ] && [ "${LAUNCHCTL_TEST_BOOTSTRAP_EXIT:-0}" != "0" ]; then
	exit "$LAUNCHCTL_TEST_BOOTSTRAP_EXIT"
fi
if [ "$1" = "enable" ] && [ "${LAUNCHCTL_TEST_ENABLE_EXIT:-0}" != "0" ]; then
	exit "$LAUNCHCTL_TEST_ENABLE_EXIT"
fi
if [ "$1" = "print" ] && [ "${LAUNCHCTL_TEST_PRINT_EXIT:-0}" != "0" ]; then
	exit "$LAUNCHCTL_TEST_PRINT_EXIT"
fi
exit 0
EOF
chmod +x "$fake_bin/launchctl"

HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" install >/dev/null

installed_script="$fake_home/.local/bin/docker-storage-cleanup"
installed_agent="$fake_home/Library/LaunchAgents/com.txema.docker-storage-cleanup.plist"
user_domain="gui/$(id -u)"

[[ -L "$installed_script" ]] || fail "cleanup executable was not linked"
[[ "$(readlink "$installed_script")" == "$cleanup_script" ]] || fail "cleanup executable points to the wrong source"
[[ -L "$installed_agent" ]] || fail "LaunchAgent was not linked"
[[ "$(readlink "$installed_agent")" == "$source_agent" ]] || fail "LaunchAgent points to the wrong source"
assert_contains "$launchctl_log" "bootstrap $user_domain $installed_agent"
assert_contains "$launchctl_log" "enable $user_domain/com.txema.docker-storage-cleanup"
assert_contains "$launchctl_log" "print $user_domain/com.txema.docker-storage-cleanup"

print "PASS: a new workstation installs and loads Docker storage cleanup"

HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" install >/dev/null
[[ "$(grep -Fc "bootstrap $user_domain $installed_agent" "$launchctl_log")" == "2" ]] ||
	fail "reinstall must reload the LaunchAgent exactly once"
print "PASS: installation is idempotent"

: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	LAUNCHCTL_TEST_BOOTSTRAP_EXIT="5" \
	"$installer" install >/dev/null 2>&1
bootstrap_failure_status=$?
set -e
[[ "$bootstrap_failure_status" == "5" ]] || fail "bootstrap failure must be returned to workstation setup"
if grep -Fq "enable $user_domain/com.txema.docker-storage-cleanup" "$launchctl_log"; then
	fail "a failed bootstrap must not report or enable a loaded job"
fi
print "PASS: LaunchAgent bootstrap failures stop workstation setup"

: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	LAUNCHCTL_TEST_ENABLE_EXIT="6" \
	"$installer" install >/dev/null 2>&1
enable_failure_status=$?
set -e
[[ "$enable_failure_status" == "6" ]] || fail "enable failure must be returned to workstation setup"
if grep -Fq "print $user_domain/com.txema.docker-storage-cleanup" "$launchctl_log"; then
	fail "a failed enable must not report a verified job"
fi

: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	LAUNCHCTL_TEST_PRINT_EXIT="7" \
	"$installer" install >/dev/null 2>&1
registration_failure_status=$?
set -e
[[ "$registration_failure_status" == "7" ]] || fail "registration verification failure must reach workstation setup"
print "PASS: enable and registration verification failures stop workstation setup"

: >"$launchctl_log"
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" status >/dev/null
assert_contains "$launchctl_log" "print $user_domain/com.txema.docker-storage-cleanup"

HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" uninstall >/dev/null
[[ ! -e "$installed_script" && ! -L "$installed_script" ]] || fail "uninstall left the executable link behind"
[[ ! -e "$installed_agent" && ! -L "$installed_agent" ]] || fail "uninstall left the LaunchAgent link behind"
assert_contains "$launchctl_log" "bootout $user_domain $installed_agent"
print "PASS: status and uninstall cover the scheduled task lifecycle"

: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" install unexpected >/dev/null 2>&1
extra_argument_status=$?
set -e
[[ "$extra_argument_status" == "64" ]] || fail "extra arguments must exit 64"
[[ ! -e "$installed_script" && ! -L "$installed_script" ]] || fail "invalid input created the executable link"
[[ ! -e "$installed_agent" && ! -L "$installed_agent" ]] || fail "invalid input created the LaunchAgent link"
[[ ! -s "$launchctl_log" ]] || fail "invalid input called launchctl"
print "PASS: invalid installer arguments have no side effects"

mkdir -p "${installed_script:h}" "${installed_agent:h}"
foreign_target="$test_root/foreign-target"
touch "$foreign_target"
ln -s "$foreign_target" "$installed_script"
: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" install >/dev/null 2>&1
foreign_script_status=$?
set -e
[[ "$foreign_script_status" == "73" ]] || fail "a foreign executable symlink must be rejected"
[[ "$(readlink "$installed_script")" == "$foreign_target" ]] || fail "foreign executable symlink was replaced"
[[ ! -e "$installed_agent" && ! -L "$installed_agent" ]] || fail "foreign executable conflict caused a partial install"
[[ ! -s "$launchctl_log" ]] || fail "foreign executable conflict called launchctl"
rm -f "$installed_script"

dangling_target="$test_root/missing-target"
ln -s "$dangling_target" "$installed_agent"
: >"$launchctl_log"
set +e
HOME="$fake_home" \
	PATH="$fake_bin:/usr/bin:/bin" \
	LAUNCHCTL_TEST_LOG="$launchctl_log" \
	"$installer" install >/dev/null 2>&1
foreign_agent_status=$?
set -e
[[ "$foreign_agent_status" == "73" ]] || fail "a foreign dangling LaunchAgent symlink must be rejected"
[[ "$(readlink "$installed_agent")" == "$dangling_target" ]] || fail "foreign dangling LaunchAgent symlink was replaced"
[[ ! -e "$installed_script" && ! -L "$installed_script" ]] || fail "foreign LaunchAgent conflict caused a partial install"
[[ ! -s "$launchctl_log" ]] || fail "foreign LaunchAgent conflict called launchctl"
rm -f "$installed_agent"
print "PASS: installation preserves foreign and dangling symlinks without partial changes"

grep -Fq '"$INSTALL_DIR/docker-storage-cleanup.sh" install' "$workstation_installer" ||
	fail "the workstation installer does not install Docker storage cleanup"
print "PASS: the main workstation setup includes Docker storage cleanup"

grep -Fq 'DOTFILES_INSTALLER_SOURCE_ONLY' "$workstation_installer" ||
	fail "the workstation installer cannot be composed safely in an isolated test"

composition_root="$test_root/composition"
composition_install="$composition_root/install"
composition_home="$composition_root/home"
component_log="$composition_root/component.log"
generic_launchctl_log="$composition_root/generic-launchctl.log"
mkdir -p "$composition_install/launchagents" "$composition_home"
touch "$composition_install/launchagents/com.txema.docker-storage-cleanup.plist"
touch "$composition_install/launchagents/com.example.generic.plist"
cat >"$composition_install/docker-storage-cleanup.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$WORKSTATION_COMPONENT_LOG"
EOF
chmod +x "$composition_install/docker-storage-cleanup.sh"

WORKSTATION_INSTALLER="$workstation_installer" \
	WORKSTATION_INSTALL_DIR="$composition_install" \
	WORKSTATION_TEST_HOME="$composition_home" \
	WORKSTATION_COMPONENT_LOG="$component_log" \
	LAUNCHCTL_TEST_LOG="$generic_launchctl_log" \
	PATH="$fake_bin:/usr/bin:/bin" \
	zsh <<'EOF' >/dev/null
export DOTFILES_INSTALLER_SOURCE_ONLY=true
source "$WORKSTATION_INSTALLER"
trap - ERR
INSTALL_DIR="$WORKSTATION_INSTALL_DIR"
HOME="$WORKSTATION_TEST_HOME"

for step in \
	validate_layout install_dotfiles install_raycast_scripts install_homebrew \
	cleanup_packages install_brew_packages restore_mackup check_karabiner_setup \
	install_launchdaemons install_node_tools configure_git configure_macos \
	install_zinit show_upgrade_deferral_status; do
	eval "$step() { :; }"
done

run_installer
EOF

[[ "$(grep -Fxc 'install' "$component_log")" == "1" ]] ||
	fail "workstation setup must invoke the dedicated installer exactly once"
if grep -Fq 'com.txema.docker-storage-cleanup.plist' "$generic_launchctl_log"; then
	fail "the generic LaunchAgent loop also handled Docker storage cleanup"
fi
grep -Fq 'com.example.generic.plist' "$generic_launchctl_log" ||
	fail "the composition test did not exercise the generic LaunchAgent loop"
print "PASS: workstation composition registers Docker cleanup exactly once"

grep -Fq '"$DOTFILES_DIR/install/docker-storage-cleanup.sh" uninstall' "$workstation_uninstaller" ||
	fail "the workstation uninstaller does not remove Docker storage cleanup"
print "PASS: the main workstation uninstall removes Docker storage cleanup"
