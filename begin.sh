#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/.config/dotfiles                    # dotfiles directory
olddir=~/.config/dotfiles/old             # old dotfiles backup directory
files="aliases bash_profile bash_prompt bashrc osx"    # list of files/folders to symlink in homedir

##########

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
rm -rf $olddir
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $dir"
    mv ~/.$file $dir/$file
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done