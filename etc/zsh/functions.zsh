#! /bin/zsh

src () {
   autoload -U zrecompile
   [ -f ~/.zsh/.zshrc ] && zrecompile -p ~/.zsh/.zshrc
   [ -f ~/.zsh/.zcompdump ] && zrecompile -p ~/.zsh/.zcompdump
   for x in $(find ~/.zsh/ -type f -name "*.zsh"); do
        zrecompile -p "${x}"
   done
   unset x
   find ~/.zsh/ -name "*.zwc.old" -exec rm -f {} \;
   source ~/.zsh/.zshrc
}
 
 
function title() {
# escape ‘%’ chars in $1, make nonprintables visible
a=${(V)1//\%/\%\%}

# Truncate command, and join lines.
a=$(print -Pn "%40>…>$a" | tr -d "\n")

case $TERM in
    screen)
    print -Pn "\e]2;$a @ $2\a" # plain xterm title
    print -Pn "\ek$a\e\\" # screen title (in ^A")
    print -Pn "\e_$2 \e\\" # screen location
    ;;
    xterm*|rxvt)
    print -Pn "\e]2;$a @ $2\a" # plain xterm title
    ;;
esac
}
 
function preexec() {
title "$1" "%m(%35<…<%~)"
}
