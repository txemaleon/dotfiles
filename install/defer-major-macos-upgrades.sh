#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROFILE="$SCRIPT_DIR/profiles/defer-major-macos-upgrades.mobileconfig"
PROFILE_ID="com.txemaleon.dotfiles.defer-major-macos-upgrades"

if [[ "${1:-}" == "--status" ]]; then
	if profiles list 2>/dev/null | grep -q "$PROFILE_ID"; then
		echo "Major macOS upgrade deferral profile is installed."
	else
		echo "Major macOS upgrade deferral profile is not installed."
	fi
	exit 0
fi

if [[ ! -f "$PROFILE" ]]; then
	echo "Profile not found: $PROFILE" >&2
	exit 1
fi

echo "Opening major macOS upgrade deferral profile..."
echo "Approve it in System Settings → Privacy & Security → Profiles."
open "$PROFILE"
