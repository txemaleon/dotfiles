#!/usr/bin/env zsh

clear

function dumpBrew { brew bundle dump --force; }

function dumpNPM { find $(npm root -g) -type d -depth 1 -print0 | sort -z | xargs -r0 basename >Npmfile; }

function dumpMackup { mackup backup --force; }

function prepare {
	clear
	dumpBrew
	dumpNPM
	dumpMackup
}

prepare
