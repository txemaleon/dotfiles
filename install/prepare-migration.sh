#!/usr/bin/env zsh

clear;

brew bundle dump --force;

find $(npm root -g) -type d -depth 1 -print0 | sort -z | xargs -r0 basename > Npmfile;

mackup backup --force;
