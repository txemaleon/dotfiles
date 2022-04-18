# macOS dotfiles

This repo installs all my personal configurations and most used applications

## To install in a new computer

```sh
mkdir -p ~/.config && cd ~/.config
git clone git@github.com:txemaleon/dotfiles.git
cd dotfiles/install
./installer.sh
```

## To prepare a migration to a new computer

```sh
cd ~/.config/dotfiles/install
./prepare-migration.sh
git commit -a -m "Update packages and new migration"
git push
```

Then in the new computer go back to install step
