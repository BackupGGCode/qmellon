#! /bin/zsh
# Search path for the cd command
cdpath=(.. / ~ ~/MyDocuments /mnt)


if [ "$TERM" = "xterm" ]; then
  xset b 4 21
else
  setterm -blength 4 -bfreq 21  #minimal click
fi


#
# Load aliaces
#
[[ -f ~/.zsh/aliases.zsh ]] && source ~/.zsh/aliases.zsh

#
# Load completion
#
[[ -f ~/.zsh/completion.zsh ]] && source ~/.zsh/completion.zsh

#
# Load functions
#
[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh


