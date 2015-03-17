#!/bin/bash

usage()
{
	echo "Usage: `basename $0` -[f|i|t][d][k][x][l language] <file>"
	echo
	echo "	Object types:"
	echo "		f	general file"
	echo "		i	image file"
	echo "		t	text file"
	echo "	Other options:"
	echo "		d	decode URL"
	echo "		k	use kdialog"
	echo "		x	xclip URL to clipboard"
	echo "		l	set language type for colorize"
}

while getopts ":fitdkxl:" OPTION
do
	case ${OPTION} in
		"f" | "i" | "t" )
			export OBJECT_TYPE="$OPTION"
		;;
		"d" )
			export DECODE=1
		;;
		"k" )
			which kdialog &> /dev/null && export K=1
		;;
		"x" )
			export XCLIP=1
		;;
		"l" )
			[[ "x" != "x${OPTARG}" ]] && export p_lang="${OPTARG}"
		;;

		* )
			usage
			exit 1
		;;
	esac
	shift $(($OPTIND - 1))
done

output() {
	[[ "x$DECODE" == "x1" ]] && URL="$(echo -en ${URL//%/\\x})"
	[[ "x$XCLIP" == "x1" ]] && echo -n "$URL" | nohup xclip -selection clipboard &> /dev/null &
	if [[ "x$OBJECT_TYPE" == "xt" ]]; then
		OUT="$URL"
	else
		OUT="$URL [$URL/preview]"
	fi
	if [[ "x$K" == "x1" ]]; then
		kdialog --msgbox "$OUT"
	else
		echo "$OUT"
	fi
}

a_file() {
	URL=$(curl -s -w %{redirect_url} -F "file=@$1" http://dump.bitcheese.net/upload-file?simple)
	output
}

a_image() {
	URL=$(curl -s -w %{redirect_url} -F "file=@$1" http://dump.bitcheese.net/upload-image?simple)
	output
}

a_text() {
	if [ -z p_lang ] ; then
		PLANG=Plaintext
	else
		PLANG="$p_lang"
	fi
	URL=$(curl -s -w %{redirect_url} -F "lang=$PLANG" -F "text=@$1" http://dump.bitcheese.net/upload-text)
	output
}


if [ -f "$1" ]; then
	if [ -z "$OBJECT_TYPE" ]; then
		case $(file -b --mime-type "$1") in
			image/* )
				export OBJECT_TYPE="i"
			;;
			text/* )
				export OBJECT_TYPE="t"
			;;
			* )
				export OBJECT_TYPE="f"
		esac
	fi
	case "$OBJECT_TYPE" in
		"f")
			a_file "$1"
		;;
		"i")
			a_image "$1"
		;;
		"t")
			a_text "$1"
		;;
			*) echo ":("
		;;
	esac
else
	echo "$1 doesn't exist or isn't a regular file"
	exit 1
fi
