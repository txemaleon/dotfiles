#!/usr/bin/env zsh

# Add SSH key to macOS keychain
if [[ -f ~/.ssh/id_rsa.pub ]]; then
	ssh-add --apple-use-keychain ~/.ssh/id_rsa
fi
