#!/usr/bin/env zsh

git config --global commit.gpgsign true
git config --global gpg.format ssh

if [[ -f ~/.ssh/id_rsa.pub ]]; then
	git config --global user.signingkey "$(cat ~/.ssh/id_rsa.pub)"
fi
