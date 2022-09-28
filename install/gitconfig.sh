#!/usr/bin/env zsh

git config --global commit.gpgsign true
git config --global gpg.format ssh

if [[ -f ~/.ssh/id_rsa.pub ]]; then
	git config --system user.signingkey "$(cat ~/.ssh/id_rsa.pub)"
	ssh-add --apple-use-keychain ~/.ssh/id_rsa
fi
