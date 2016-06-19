# Load bash_prompt aliases exports functions inputrc from ~/.config/dotfiles
# and from ~/.* for per-system overrides
for file in bash_prompt aliases exports functions inputrc; do
  dotfile="$HOME/.config/dotfiles/$file"
  [ -e "$dotfile" ] && source "$dotfile"
  homefile="$HOME/.$file"
  [ -e "$homefile" ] && source "$homefile"
done
unset dotfile homefile

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2)" scp sftp ssh
