#! /bin/zsh

# Enable colors for ls completion, etc
# LS_COLORS=`eval dircolors`
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# ROOTPATH for sudo
zstyle -e ':completion:*:sudo:*' command-path 'reply=($path /opt/nessus/sbin /usr/sbin /usr/local/sbin /sbin)'

# Describe options in full
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'

#zstyle ':completion:*:history-words' stop yes
#zstyle ':completion:*:history-words' remove-all-dups yes
#zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

### Forcing the rehash
_force_rehash() {
(( CURRENT == 1 )) && rehash
return 1
}

### Loading the completion style
zstyle ':completion:*' completer _expand _force_rehash _complete _ignored _approximate
zstyle ':completion:predict:*' completer _force_rehash _complete

_packages () {
    if compset -P '(\\|)(>=|<=|<|>|=)'  ; then
            _gentoo_packages ${*/(#m)(installed|available)/${MATCH}_versions}
    else
            _gentoo_packages $*
    fi
}

if [[ "x$service" == "xeless" ]]; then
	_arguments ':portage:_packages available'
fi
