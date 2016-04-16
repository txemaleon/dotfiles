# source "$HOME/.bash_profile"
NPM_PACKAGES=~/.npm-packages
NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
PATH="$NPM_PACKAGES/bin:$PATH"

COMPOSER_PATH=~/.composer/vendor/bin
PATH="$COMPOSER_PATH:$PATH"
