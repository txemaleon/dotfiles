# Load ~/.bash_prompt, ~/.bashrc, ~/.aliases and ~/.extra
# ~/.extra can be used for settings you don’t want to commit
for file in bash_prompt aliases functions inputrc; do
  dotfile="$HOME/.config/dotfiles/$file"
  [ -e "$dotfile" ] && source "$dotfile"
  homefile="$HOME/.$file"
  [ -e "$homefile" ] && source "$homefile"
done

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
complete -W "NSGlobalDomain" defaults
