#! /bin/zsh

# Set up aliases
alias mv='nocorrect mv'       # no spelling correction on mv
alias cp='nocorrect cp'       # no spelling correction on cp
alias eix='nocorrect eix' # no spelling correction on mkdir
alias esearch='nocorrect esearch' # no spelling correction on mkdir
alias equer='nocorrect equery' # no spelling correction on mkdiralias 
alias emerge='nocorrect emerge' # no spelling correction on mkdiralias 
alias dep='nocorrect dep' # no spelling correction on mkdiralias 

alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias grep='grep --colour=auto'

alias zcalc='autoload -U zcalc; zle -N zcalc; zcalc'

# alias j=jobs
# alias pu=pushd
# alias po=popd
# alias d='dirs -v'
# alias h=history
# alias grep=egrep
# alias ll='ls -l'
# alias la='ls -a'
#
# # List only directories and symbolic
# # links that point to directories
# alias lsd='ls -ld *(-/DN)'
# 
# # List only file beginning with "."
# alias lsa='ls -ld .*'
#
# Global aliases -- These do not have to be
# at the beginning of the command line.
alias -g M='|more'
alias -g H='|head'
alias -g T='|tail'
