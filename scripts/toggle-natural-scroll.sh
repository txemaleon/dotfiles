#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Toggle Natural Scroll – Mouse and Trackpad
# @raycast.mode compact
# @raycast.icon 🖱️
# @raycast.packageName System

# Lee el valor actual (1 = natural, 0 = clásico). Si no existe, asume 1.
current=$(defaults read -g com.apple.swipescrolldirection 2>/dev/null || echo 1)

if [ "$current" = "1" ]; then
	defaults write -g com.apple.swipescrolldirection -bool false
	label="OFF (clásico)"
else
	defaults write -g com.apple.swipescrolldirection -bool true
	label="ON (natural)"
fi

# Fuerza a macOS a releer la preferencia en caliente (sin cerrar sesión).
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

echo "Scroll natural: $label"
