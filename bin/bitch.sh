#!/bin/bash

usage()
{
	echo "Usage: `basename $0` -[f|i|t][k][x][l language] <file>"
	echo
	echo "	Object types:"
	echo "		f	general file"
	echo "		i	image file"
	echo "		t	text file"
	echo "	Other options:"
	echo "		k	use kdialog"
	echo "		x	xclip URL to clipboard"
	echo "		l	set language type for colorize"
}

while getopts ":fitkxl:" OPTION
do
	case ${OPTION} in
		"f" | "i" | "t" )
			export OBJECT_TYPE="$OPTION"
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

a_file() {
	URL=$(curl -s -w %{redirect_url} -F "file=@$1" http://dump.bitcheese.net/upload-file?simple)
	[[ "x$XCLIP" == "x1" ]] && echo -n "$URL" | nohup xclip -selection clipboard &> /dev/null &
	if [[ "x$K" == "x1" ]]; then
		kdialog --msgbox "$URL [$URL/preview]"
	else
		echo "$URL [$URL/preview]"
	fi
}

a_image() {
	URL=$(curl -s -w %{redirect_url} -F "file=@$1" http://dump.bitcheese.net/upload-image?simple)
	[[ "x$XCLIP" == "x1" ]] && echo -n "$URL" | nohup xclip -selection clipboard &> /dev/null &
	if [[ "x$K" == "x1" ]]; then
		kdialog --msgbox "$URL [$URL/preview]"
	else
		echo "$URL [$URL/preview]"
	fi
}

a_text() {
	if [ -z p_lang ] ; then
		PLANG=Plaintext
	else
		PLANG="$p_lang"
	fi
	URL=$(curl -s -w %{redirect_url} -F "lang=$PLANG" -F "text=@$1" http://dump.bitcheese.net/upload-text)
	[[ "x$XCLIP" == "x1" ]] && echo -n "$URL" | nohup xclip -selection clipboard &> /dev/null &
	if [[ "x$K" == "x1" ]]; then
		kdialog --msgbox "$URL [$URL/preview]"
	else
		echo "$URL"
	fi
}


if [ -f "$1" ]; then
	if [ -n "$OBJECT_TYPE" ]; then
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
		case $(file -b --mime-type "$1") in
			image/* )
				a_image "$1"
			;;
			text/* )
				a_text "$1"
			;;
			* )
				a_file "$1"
		esac
	fi
else
	echo "$1 doesn't exist or isn't a regular file"
	exit 1
fi
