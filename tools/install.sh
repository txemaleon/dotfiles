#!/usr/bin/env zsh

for f in config/*;
do
	rm -rf ~/.$f;
	echo "Linking $f"
	ln -s ~/.config/dotfiles/config/$f ~/.$f;
done
