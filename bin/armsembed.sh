#! /bin/bash

# armsembed.sh
# Author:  Mellon, <qmellon{@}gmail{dot}com>

print_usage() {
echo "Использование: $(basename "$0") [-ed РЕДАКТОР] [-xe X-РЕДАКТОР] [-xt X-ТЕРМИНАЛ] [-g [combobox|menu]] [-k ИДЕНТИФИКАТОР_КЛЮЧА] [-v] ФАЙЛ"
echo "               $(basename "$0") [-h]"
}

print_help() {
echo "Использование: $(basename "$0") [-ed РЕДАКТОР] [-xe X-РЕДАКТОР] [-xt X-ТЕРМИНАЛ] [-g [combobox|menu]] [-k ИДЕНТИФИКАТОР_КЛЮЧА] [-v] ФАЙЛ"
echo "               $(basename "$0") [-h]"
echo
echo "Скрипт предназначен для создания непрозрачной ЭЦП и её записи"
echo "в редактируемый файл заданный аргументом(параметром)."
echo "Создан для встраивания в браузеры поддерживающие редактирование сторонними"
echo "программами."
echo "Примеры браузеров: w3m, elinks, seamonkey и firefox с соответвующим расширением"
echo "http://mozex.mozdev.org/ , и т.д.)"
echo
echo "Параметры:"
echo "	-ed	предпочитаемый консольный редактор, если не задан, то берётся из переменной EDITOR, если не задана, то используется nano"
echo "	-xe	предпочитаемый графический редактор текста, если не задан, то берётся из переменной XEDITOR, если не задана, то используется kedit"
echo "	-xt	предпочитаемый X-терминал, если не задан, то берётся из переменной XTERM, если не задана, то используется xterm"
echo "	-g	включает графические диалоги выбора ключа и ввода пароля (ПОТЕНЦИАЛЬНО ОПАСНО). Также можно указать тип диалога выбора ключа: combobox или menu. Требует наличия установленного kdialog"
echo "	-k	малый цифробуквенный идентификатор секретного ключа"
echo "	-v	выводить более подробную информацию о доступных ключах"
echo "	-h	вывод этой справки"
}

# Анализ аргументов
# =====================================================

ARGS="$*"
until [ -z "$1" ] ; do
	case "$1" in
		"-ed" )
			EDITOR="$2"
	;;	
		"-xe" )
			[[ "x$2" != "x" ]] && XEDITOR="$2"
	;;
		"-xt" )
			[[ "x$2" != "x" ]] && XTERM="$2"
	;;
		"-g" )
			[[ "x$2" == "xmenu" || "x$2" == "xcombobox" ]] && GUI_MODE="$2"
			: ${GUI_MODE:="combobox"}
			export GUI_MODE
	;;
		"-h" )
			print_help && exit 0
	;;
		"-k" )
			[[ "x$2" != "x" ]] && CHOISED_KEYID="$2"
	;;
		"-v" )
			VERBOSE=1
	;;
		* )
			FILE="$1"
	;;
	esac
	shift
done

# Проверка синтаксиса вызова
if [[ "x" == "x$FILE" ]] ; then
print_usage
exit 7
fi

# =====================================================

# Программы в кавычках замените своими любимыми программами,
# если они уже не заданы аргументамми, или глобально системными переменными.

# Редактор для терминала:
: ${EDITOR:="nano"}
# Редактор для x-ов:
: ${XEDITOR:="kate"}
# Подробный вывод информации о ключах:
: ${VERBOSE:="0"}
# X эмулятор терминала:
: ${XTERM:="xterm"}

# Вид GUI для GnuPG [combobox/menu] (ПОТЕНЦИАЛЬНО ОПАСНО):
# : ${GUI_MODE:="menu"}
# 	Заголовок:
	: ${GUI_TITLE:="Выбор ключа"}
# 	Запрс:
	: ${QUERY:="Выберите ключ для подписи:"}
#	Размеры GUI menu:
	: ${MENU_GEOMETRY:="800x250"}
# 	Заголовок парольного диалога:
	: ${PASSWORD_TITLE:="Пароль"}
# 	Запрс пароля:
	: ${PASSWORD_QUERY:="Введите ключевую фразу (пароль) для"}

# =====================================================

tmp=$(tempfile || echo /tmp/tmp_)
CHOISED_KEY=""
BROKEN_GUI=""

# Группировка вывода списка доступных секретных ключей
KEYID="$(gpg -K | grep 'sec ' | sed s/'sec\s*'/''/ | sed s/'.*\/'// | sed s/' .*'//)"
TERM_INFO="$(gpg -K | grep 'sec ' | sed s/'sec\s*'/''/ | sed s/'.*\/'// | sed s/'[A0-Z9]* '/''/)"
KEYNAME="$(gpg -K | grep 'uid' | sed s/'uid\s*'/''/)"

verbose_list_keys() {
	echo $(paste -d ' ' <(echo "${KEYID}") <(echo "${TERM_INFO}") <(echo "${KEYNAME}") | sed s/'$'/';'/) | sed s/'; '/';'/g
}

list_keys() {
	echo $(paste -d ' ' <(echo "${KEYID}") <(echo "${KEYNAME}") | sed s/'$'/';'/) | sed s/'; '/';'/g
}

choise_of_lists_keys() {
	if [[ "x${VERBOSE}" == "x1" ]]; then
		verbose_list_keys
	else
		list_keys
	fi
}

choice_of_keys() {
	PS3_OLD="${PS3}"
	PS3='Выберите ключ для подписания: '
	echo
	LIST_KEYS="$(choise_of_lists_keys)"
	OLD_IFS=$IFS
	IFS=';'
	select CHOISED_KEY in ${LIST_KEYS}
	do
		echo
		echo "Вы выбралм ключ $CHOISED_KEY."
		echo ";-))"
		echo
		break
	done
	IFS=$OLD_IFS
	PS3="${PS3_OLD}"
	CHOISED_KEYID="$(echo "${CHOISED_KEY}" | sed s/' .*'//)"
	# Комманда подписи для терминала.
	COMMAND="gpg --yes --output "$tmp" -u 0x$CHOISED_KEYID -sa ${FILE}"
}

# Функции GUI
#
# =====================================================

gui_list_keys() {
	case "${GUI_MODE}" in
		"combobox" )
			choise_of_lists_keys
			;;
		"menu" )
			if [[ "x${VERBOSE}" == "x1" ]]; then
				echo $(paste -d ';' <(echo "${KEYID}") <(paste -d ' '  <(echo "${KEYID}") <(echo "${TERM_INFO}") <(echo "${KEYNAME}")) | sed s/'$'/';'/) | sed s/'; '/';'/g
			else
				echo $(paste -d ';' <(echo "${KEYID}") <(paste -d ' ' <(echo "${KEYID}") <(echo "${KEYNAME}")) | sed s/'$'/';'/) | sed s/'; '/';'/g
			fi			
			;;
	esac
}

gui_menu() {
	LIST="$(gui_list_keys)"
	OLD_IFS=$IFS
	IFS=';'
	kdialog --title "${GUI_TITLE}" --geometry ${MENU_GEOMETRY} --menu "${QUERY}" ${LIST}
	IFS=$OLD_IFS
	
}

gui_combobox() {
  	LIST="$(gui_list_keys)"
	OLD_IFS=$IFS
	IFS=';'
	kdialog --title "${GUI_TITLE}" --combobox "${QUERY}" ${LIST}
	IFS=$OLD_IFS
}

gui_password() {
	kdialog --title "${PASSWORD_TITLE}"  --password "${PASSWORD_QUERY} ${CHOISED_KEY}:"
}

gui_sign() {
	while true
	do 
	gui_password | gpg --yes --batch --output $tmp -u 0x$CHOISED_KEYID --passphrase-fd 0 -sa ${FILE} && break
	kdialog --warningyesno "Не верный пароль, повторить попытку?" || exit 4
	done
}

gui_commands() {
	CHOISED_KEY="$(gui_${GUI_MODE})"
	[[ "x$CHOISED_KEY" == "x" ]] && exit 5
	CHOISED_KEYID="$(echo "${CHOISED_KEY}" | sed s/' .*'//)"
	# Комманда подписи для GUI.
	COMMAND="gui_sign"
}

restart_in_xterm() {
# Проблемы с графическими программами, используем эмулятор терминала
# (если он есть, иначе выходим с ошибкой)
[[ -x "$(which ${XTERM})" ]] && $(echo ${XTERM} -e "$0" "$FILE") && exit 0 || exit 2
}

 # =====================================================

# Комманда выбора ключа для терминала.
: ${SELECT_KEY:="choice_of_keys"}

if [[ "x${TERM}" == "xdumb" ]]; then
# Терминал немой.
# 	Мы в иксах?
	if [[ "x" != "x${DISPLAY}" ]]; then
# 		Есть ли любимый редактор для x-ов?
		if [[ "x" != "x${XEDITOR}" && -f "$(which ${XEDITOR})" ]]; then
			export EDITOR="${XEDITOR}"
			else
# 			Редактор не найден.
			BROKEN_GUI=1
		fi

# 		Активировано и доступно ли GUI?
 		if [[ "x" != "x${GUI_MODE}" && -x $(which kdialog) ]]; then
			export SELECT_KEY="gui_commands"
		else
# 			GUI не активировано или не доступно.
			BROKEN_GUI=1
		fi
		
		[[ "x$BROKEN_GUI" == "x1" ]] && restart_in_xterm
		
	else
# 		Мы не в иксах. Если всё-таки, вы в графике, то для определения этого факта
# 		попробуйте подобрать другую системную переменную нежели 'DISPLAY'.
		exit 3
	fi
fi

echo "Пожалуиста, напишите новый, или отредактируйте исходный текст"
echo "в открывшемся редакторе перед его подписанием"
echo
echo "======================================================"
"$EDITOR" "$FILE"
echo "======================================================"
echo
[[ -f "$FILE" && "x$(cat "$FILE" | wc -m)" != "x0" ]] && ${SELECT_KEY} && ${COMMAND}
# здесь ЭЦП добавляется в файл:
echo >> "$FILE"
cat $tmp >> "$FILE"
# если нужна только подпись:
# cat $tmp > "$FILE"
sleep 15
rm -f $tmp
exit $?
