#! /bin/bash

# kl.sh
# Author: Mellon, <qmellon at gmail dot com>


FLAG_D=""
FLAG_I=""
FLAG_H=""
FLAG_R=""
FLAG_T=""
CONFIG_PATH=""
KERNEL_SOURCES_PATH=""
ITEM=""
GVAR=""

tmp1=$(tempfile || echo /tmp/kl_tmp1_)

until [ -z "$1" ] ; do
	case "$1" in
		"-d" )
			FLAG_D=1
	;;	
		"-i" )
			FLAG_I=1
	;;
		"-c" )
			[[ -z "$2" && -f "$2" ]] && CONFIG_PATH="$2"
	;;
		"-s" )
			[[ -z "$2" && -f "$2/kernel/Makefile" ]] && KERNEL_SOURCES_PATH="$2"
	;;
		"-h" )
			FLAG_H=1
	;;
		"-r" )
			FLAG_R=1
	;;
		"-t" )
			FLAG_T=1
	;;
		* )
			ITEM="$1"
	;;
	esac
	shift
done

if [ ! -z "$FLAG_H" ] ; then
	echo "	$(basename $0) [-c <kernel config>] [-d] [-h] [-i] [-r] [-s <kernel sources] [-t] [parameter|description]"
	echo "	-c <kernel config>	the path name of kernel config file"
	echo "	-d	use descriptions of parameter"
	echo "	-h	display this help and exit"
	echo "	-i	interpretation"
	echo "	-r	rebuild db (works only with '-d')"
	echo "	-s <kernel sources>	the path name of kernel config file"
	echo "	-t	translate parameter <-> description"
	echo "	parameter|description	kernel parameter, or description of parameter"
	exit 0
fi

if [ -z "$CONFIG_PATH" ] && [ -f "/usr/src/linux/.config" ] ; then 
	CONFIG_PATH="/usr/src/linux/.config"
elif [ -f "/proc/.config.gz" ] ; then 
	zcat /proc/.config.gz > $tmp1
	CONFIG_PATH="$tmp1"
else
	while [[ ! -f "$CONFIG_PATH" ]]
	do
	echo "едрён батон! где ядрён конфиг???"
	read CONFIG_PATH
	[[ $CONFIG_PATH = "quit" ]] && exit 0
	done
fi

[[ -z "${KERNEL_SOURCES_PATH}" && -f "$(dirname $CONFIG_PATH)/kernel/Makefile" ]] && KERNEL_SOURCES_PATH="$(dirname $CONFIG_PATH)"

get_item() {
	echo "Введите параметр ядра:"
	read ITEM
	[[ $ITEM = "quit" ]] && exit 0
}

grep_item_from_config() {
	GVAR="$(echo "$ITEM" | xargs -r -L 1 -I item grep item $CONFIG_PATH | grep CONFIG)"
	return $?
}

clean_item() {
	CLEAN_ITEM=( $(echo "$GVAR" | sed s/'^# CONFIG'/'CONFIG'/g | sed s/'=.*\| .*'/''/g) )
	[[ ! $? = "0" ]] && exit 1
}

item_state() {
	ITEM_STATE="$(echo "$GVAR" | sed s/'.*='/''/ | sed s/'.*is not set'/'is not set'/)"
}

item_state_interpretation() {
	_ITEM_STATE=( "$(echo "$ITEM_STATE" | sed s/'is not set'/'is_not_set'/)" )
	ITEM_STATE_INTERPRETATION="$({
		for SINGLE_ITEM_STATE in ${_ITEM_STATE[*]}; do
		item_state_interpretation_choise
		done
	})"
}

item_state_interpretation_choise() {
	case "$SINGLE_ITEM_STATE" in
		"y" )
			echo "вкомпилен в ядро"
		;;
		"m" )
			echo "скомпилен модулем"
		;;
		"is_not_set" )
			echo "не задан"
		;;
		* )
			echo "шозанах?"
		;;
	esac
}



build_db() {
	find $KERNEL_SOURCES_PATH/ -name Kconfig -exec cat {} \; | sed /'^$'/d | grep '^\S*bool \|\S*tristate ' -B 1 | sed s/'^#\|\t*\|^ *'//g | sed s/'^\S*bool \|^\S*tristate '/''/g | sed s/' \{2\}'/' '/g | sed /'^--$'/d | sed s/'^config *\|^menuconfig *'/'CONFIG_'/g > ~/.kl
	[[ ! $? = "0" ]] && exit 1
}

clean_desc_from_db() {
	CLEAN_DESC="$(cat ~/.kl | sed s/\'//g | sed s/\"//g |grep -v 'CONFIG_' | grep -i "$ITEM")"
}

grep_desc_from_db() {
	DESC_FROM_DB="$(echo "$CLEAN_DESC" | xargs -r -L 1 -I single_item grep single_item  -m 1 -B 1 ~/.kl)"
	return $?
}

grep_item_from_db() {
#	ITEM_FROM_DB="$(echo "${GVAR}" | xargs -r -L 1 -I single_item grep single_item -A 1 ~/.kl)"
	ITEM_FROM_DB="$(grep "${GVAR}" -x -m 1 -A 1 ~/.kl)"
	[[ "X${ITEM_FROM_DB}" = "X" ]] && return 1
}

find_desc_from_db() {
	FDESC="$(echo "$ITEM_FROM_DB" | grep -v -e '^\n*--\n*$' | sed /'^$'/d | sed /'^CONFIG.*$'/d)"
	return $?
}

find_item_from_db() {
	ITEM="$(echo "$DESC_FROM_DB" | grep 'CONFIG_')"
	return $?
}

#####################  OUTPUT  GENERATION #####################

gen_base_output() {
	grep_item_from_config
	item_state
	clean_item
	GVAR="$({
		for G in ${CLEAN_ITEM[*]} ; do
		echo $G
		done
		})"
}

gen_desc_output() {
	clean_desc_from_db
	grep_desc_from_db
	find_item_from_db
	gen_base_output
}

gen_interpretation_output(){
	if [ -z "$FLAG_I" ] ; then
		echo "${ITEM_STATE}" | sed s/'^'/'= '/
	else
		item_state_interpretation
		echo "$ITEM_STATE_INTERPRETATION"
	fi
}

translation() {
	_GVAR="$({
		for GVAR in ${CLEAN_ITEM[*]} ; do
			grep_item_from_db
			find_desc_from_db
			[[ -z $FDESC ]] && FDESC="${GVAR}"
			echo "$FDESC"
		done
	})"
	GVAR="${_GVAR}"
}

gen_output() {
	if [ ! -z "$FLAG_D" ]; then
		gen_desc_output
		[[ ! -z "$FLAG_T" ]] && translation
		paste -d ' ' <(echo "$GVAR" | xargs -L 1 echo) <(gen_interpretation_output | xargs -L 1 echo)
	else
		gen_base_output
		[[ ! -z "$FLAG_T" ]] && translation 
		paste -d ' ' <(echo "$GVAR" | xargs -L 1 echo) <(gen_interpretation_output | xargs -L 1 echo)
	fi
}

[[ ! -z "$FLAG_D" || ! -z "$FLAG_T" ]] && [[ ! -f ~/.kl || ! -z "$FLAG_R" ]] && build_db

if [ ! -z $ITEM ] ; then
	gen_output
else
	while true
	do
		get_item
		gen_output
	done
fi

rm -f $tmp1

exit $?
