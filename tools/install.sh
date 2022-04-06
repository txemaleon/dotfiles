#!/usr/bin/env zsh

for f in profile fixpackrc gitconfig gitignore inputrc npmrc tmux.conf vimrc zshrc;
do
	rm -rf ~/.$f;
	echo "Linking $f"
	ln -s ~/.config/dotfiles/$f ~/.$f;
done
