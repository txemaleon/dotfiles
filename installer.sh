#!/usr/bin/env bash

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Brew Stuff
brew install \
	ansible \
	bash-completion2 \
	boost \
	brew-cask-completion \
	bundler-completion \
	cabextract \
	cairo \
	cloog \
	composer \
	composer-completion \
	czmq \
	faac \
	ffmpeg \
	fontconfig \
	fontforge \
	freetype \
	gcc \
	gdbm \
	gettext \
	gist \
	git-flow \
	glib \
	gmp \
	gobject-introspection \
	hardlink-osx \
	harfbuzz \
	highlight \
	htop-osx \
	httpie \
	icu4c \
	isl \
	jp2a \
	jpeg \
	lame \
	lftp \
	libffi \
	libmpc \
	libpng \
	libsodium \
	libtiff \
	libtool \
	libxml2 \
	libyaml \
	lua \
	mongodb \
	mpfr \
	node4-lts \
	openssl \
	pango \
	pcre \
	php70 \
	phplint \
	pixman \
	pkg-config \
	pwgen \
	python \
	python3 \
	readline \
	ruby \
	sqlite \
	ssh-copy-id \
	texi2html \
	unixodbc \
	vagrant-completion \
	wget \
	wifi-password \
	wpcli-completion \
	x264 \
	xvid \
	xz \
	yasm \
	youtube-dl \
	zeromq \
	zlib \

# Brew Cask
brew tap caskroom/cask
brew cask install --force \
    betterzipql \
    colorpicker-developer \
    colorpicker-skalacolor \
    qlcolorcode \
    qlmarkdown \
    qlprettypatch \
    qlstephen \
    qlvideo \
    quicklook-json \
    quicknfo \
    suspicious-package \
    webpquicklook \
    xquartz

# NPM
npm install -yg \
	bipio \
	bower \
	bower-installer \
	clean-css \
	cordova \
	electron \
	electron-prebuilt \
	generator-electrode \
	grunt \
	grunt-cli \
	gulp \
	hbcrawler \
	how-to-npm \
	html-minifier \
	ios-deploy \
	ios-sim \
	javascripting \
	js-beautify \
	jshint \
	kerberos \
	learnyoumongo \
	learnyounode \
	mean-cli \
	minjson \
	mocha \
	mongodb-core \
	muffin \
	muffin-cli \
	mversion \
	now \
	npm \
	perfschool \
	phantomjs \
	rabbit.js \
	scope-chains-closures \
	sinclair-cli \
	stream-adventure \
	svgo \
	takana \
	test-anything \
	uglify-js \
	uglifycss \
	uglifyjs \
	underscores \
	webpack \
	yo \

rm -rf ~/.bash* ~/.inputrc
ln -s ~/.config/dotfiles/bashrc ~/.bashrc
ln -s ~/.config/dotfiles/inputrc ~/.inputrc
