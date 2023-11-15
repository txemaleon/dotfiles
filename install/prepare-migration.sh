#!/usr/bin/env zsh

function dumpBrew { brew bundle dump --force; }

function dumpNPM { npm list -pg --depth=0 | sed -e "s/├── //" -e "s/│ //" -e "s/└── //" -e "s~$(npm root -g)\/~~" -e "/^-$/d" -e "/\/usr\/local/d" | sed -e "/^(\s*)$/d" | sort -z | tr -d '\000' >Npmfile; }

function dumpMackup {
	mackup backup --force
	mackup uninstall --force
}

function prepare {
	clear
	dumpBrew
	dumpNPM
	dumpMackup
}

clear
prepare
