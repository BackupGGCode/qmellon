#! /bin/zsh

# Например cd. cd <Tab>, выбрали каталог, хотим выбрать следующий, уровнем ниже (рекомендуется для использования совместно с описаным vyt@ "^M" .accept-line):
bindkey -M menuselect "/" accept-and-infer-next-history

# Ходим по меню, выделяем об'екты пробелом:
bindkey -M menuselect " " accept-and-menu-complete

# Ctrl-BackSpace отмена последнего дополнения
bindkey -M menuselect "^[[23~" undo

# Это заклинание при нажатии в меню Enter сразу принимает вариант.
# Например, при переходе в каталог не надо жать Enter дважды.
bindkey -M menuselect "^M" .accept-line