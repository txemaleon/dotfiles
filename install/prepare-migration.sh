#!/usr/bin/env zsh

SCRIPT_DIR=$(dirname "${0:A}")

function dumpBrew { brew bundle dump --force --no-vscode --file="$SCRIPT_DIR/Brewfile"; }

function dumpNPM { npm list -pg --depth=0 | sed '1d' | sed -e "s/├── //" -e "s/│ //" -e "s/└── //" -e "s~$(npm root -g)\/~~" -e "/^-$/d" -e "/\/usr\/local/d" | sed -e "/^(\s*)$/d" | sort -z | tr -d '\000' >"$SCRIPT_DIR/Npmfile"; }

function dumpMackup {
	mackup backup --force
}

function prepare {
	clear
	dumpBrew
	dumpNPM
	dumpMackup
}

clear
prepare
