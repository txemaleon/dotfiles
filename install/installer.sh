#!/usr/bin/env zsh

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do
	sudo -n true
	sleep 60
	kill -0 "$$" || exit
done 2>/dev/null &

# Install dotfiles
DOTFILES=$(dirname ${0:a:h})
for FILE in $DOTFILES/config/*; do
	f=$(basename $FILE)
	rm -rf ~/.$f
	echo "Linking $FILE => .$f"
	ln -s $FILE ~/.$f
done

# Install HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle

# Link mackup
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/.config/.mackup ~/.mackup
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/.config/.mackup.cfg ~/.mackup.cfg
mackup restore

# Install node tools
sed 's/#.*//' Npmfile | xargs npm install -g

# Install ssh key
./gitconfig.sh

# Configure macos
. ./macos.sh

# Oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cd ~/.oh-my-zsh/custom/plugins
gh repo clone Aloxaf/fzf-tab
gh repo clone zsh-users/zsh-autosuggestions
gh repo clone zsh-users/zsh-syntax-highlighting
