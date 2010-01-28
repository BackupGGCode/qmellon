#! /bin/bash

# armsgen.sh
#
# скрипт создает и проверяет непрозрачные ЭЦП
# для проверки ЭЦП создайте симлинк armsver.sh ссылающийся на этот скрипт
# и запускайте с этой ссылки.


: ${EDITOR:="nano"}
COMMAND="gpg -sa"
[[ "$(basename $0)" == "armsver.sh" ]] && COMMAND="gpg -dv" 

if [[ "x$1" != "x" ]] ; then
	if [[ -f "$1" ]] ; then
		$COMMAND "$1"
	else
		echo "$1" | $COMMAND
	fi
else
	while true
	do
		tmp=$(tempfile || echo /tmp/tmp_$RANDOM)
		$EDITOR $tmp
		[[ "x$(cat $tmp | wc -m)" != "x0" ]] && cat $tmp | $COMMAND
		rm -f $tmp
		echo "Ещё? Если хватит, то введите любой символ и нажмите ввод"
		read TEXT
		[[ "x$TEXT" == "x" ]] || exit 0
	done
fi

exit $?
