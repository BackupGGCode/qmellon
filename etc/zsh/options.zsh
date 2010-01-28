#! /bin/zsh

# correction
setopt correctall

# print exit value
setopt printexitvalue

# setting extended globbing
setopt extendedglob

# history
setopt  hist_ignore_all_dups
setopt  hist_ignore_space
setopt  hist_reduce_blanks
setopt  hist_save_no_dups
setopt  share_history

setopt   correct
setopt   notify globdots pushdtohome cdablevars autolist
setopt   autocd recexact longlistjobs
setopt   autoresume histignoredups pushdsilent noclobber
setopt   autopushd pushdminus rcquotes
unsetopt bgnice 
unsetopt autoparamslash
unsetopt nomatch
