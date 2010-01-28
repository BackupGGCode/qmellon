#! /bin/zsh

autoload -U compinit
compinit

autoload -U predict-on
zle -N predict-on
zle -N predict-off
zstyle ':predict' verbose 1
zle-line-init() { predict-on }
zle -N zle-line-init

zmodload zsh/complist
setopt menucomplete
# setopt automenu
zstyle ':completion:*' menu yes select
# zstyle ':completion:*' menu select=long

# сompletion style improvements
zstyle ':completion:*' verbose yes
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BНет соответствий для: %d%b'
zstyle ':completion:*:corrections' format '%B%d (ошибки: %e)%b'
zstyle ':completion:*' group-name ''
export SPROMPT="Ошибка! Вы хотели ввести %r вместо %R? ([Y]es/[N]o/[E]dit/[A]bort) "

# list of completers to use
# zstyle ':completion:*::::' completer _expand _complete _ignored _approximate
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:predict:*' completer _complete

# allow one error for every three characters typed in approximate completer
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

# insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# formatting and messages

# match uppercase from lowercase
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# command for process lists, the local web server details and host completion
#zstyle ':completion:*:processes' command 'ps -o pid,s,nice,stime,args'
zstyle ':completion:*:processes' command 'ps -xuf'
zstyle ':completion:*:processes' sort false
zstyle ':completion:*:processes-names' command 'ps xho command'
#zstyle ':completion:*:urls' local 'www' '/var/www/htdocs' 'public_html'
zstyle '*' hosts $hosts

# Filename suffixes to ignore during completion (except after rm command)
# zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~'     '*?.old' '*?.pro'
# the same for old style completion
#fignore=(.o .c~ .old .pro)

# ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'

# enable cache for the completions
zstyle ':completion::complete:*' use-cache 0
