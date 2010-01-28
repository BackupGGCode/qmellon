#! /bin/bash

# @(#) ape2flac 0.2 18/10/2008 by Mellon
# Refactoring.
#
# now script can convert ape to splited flacs,
# smartly recode russian cuesheets
# embed tags from cuesheet to splited flacs
# delete unnecessary ape file by promt
# 
# Usage ape2flac.sh [-d|-p] [-s] [target directory]
# 
# -d	force deleteing ape-files
# -p	prompt deleteing ape-files
# -s	convert ape to splited flacs
# 
#
# Dependencies:
# 
# media-sound/mac
#      Homepage:            http://sourceforge.net/projects/mac-port
#      Description:         unix port of Monkey's Audio
# 
# app-i18n/enca
#      Homepage:            http://trific.ath.cx/software/enca/
#      Description:         ENCA detects the character coding of a file and converts it if desired
# 
# media-libs/flac
#      Homepage:            http://flac.sourceforge.net
#      Description:         free lossless audio encoder and decoder
# 
# media-sound/shntool
#      Homepage:            http://shnutils.freeshell.org/shntool/
#      Description:         shntool is a multi-purpose WAVE data processing and reporting utility
# 
# app-cdr/cuetools
#      Homepage:            http://developer.berlios.de/projects/cuetools/
#      Description:         Utilities to manipulate and convert cue and toc files
# 
# 
# TODO:
# 
# Fix tree building


# @(#) ape2flac 0.1b 23/01/2007 by BaBL
# Checking for mac & flac
# Checking for input directory
#
# @(#) ape2flac 0.1a 14/01/2007 by BaBL
# Fixed a bug identifying filenames with more then one "." symbol
#
# @(#) ape2flac 0.1 26/09/2003 by Peo Karlsson
#
# Recursively convert APE-files to FLAC.
# Directory recursion adapted from the 'tree' script by Jordi Sanfeliu (see below).
#
#
#
# @(#) tree 1.1 30/11/1995 by Jordi Sanfeliu (mikaku@fiwix.org)
#
# Initial version: 1.0 30/11/95
# Next version : 1.1 24/02/97 Now, with symbolic links
#

SPLIT=""
CUE_FILE=""
PROG=`basename $0`
declare -a prog_needed=(mac flac  shnsplit enca cueprint)

# which extension to look for when browsing the tree
MYEXT="ape"

# Process arguments
while [ $# -ne 0 ]; do
	[ "$1" == "-d" ] && DELETE=force
	[ "$1" == "-p" ] && DELETE=prompt
	[ "$1" == "-s" ] && SPLIT=1
	TARGET_DIRECTORY=$1
	shift
done

findcuefile() {
	 k="$(find "$(dirname "$TARGET")" -maxdepth 1 -type f -iname "$BASE.ape.cue" -printf "%f\n")"
	 [[ "x$k" == "x" ]] && k="$(find "$(dirname "$TARGET")" -maxdepth 1 -type f -iname "$BASE.cue" -printf "%f\n")"
	 echo "$k"
}

convert() {
	mac "$TARGET" - -d | flac -V -8 -e -p -o "$BASE.flac" -
}

convertandsplit() {
	shnsplit -i ape -o 'flac flac -V -8 -e -p -o %f -' -t %n "$TARGET" < "$TEMPCUE"
}

recodecue() {
	CHARSET="$(enca -i "$TEMPCUE")"
	if [[ "$CHARSET" == "CP1251" || "$CHARSET" == "KOI8-R" || "$CHARSET" == "UTF-8" ]]; then
	enconv -L ru -x utf8 "$TEMPCUE"
	fi
}

# embed tags into tracks, rename tracks
embedtags() {
	for (( i=1; i <= $(cueprint -d '%N' "$TEMPCUE"); ++i )); do
		NN=$(printf '%02d' $i)
		[ -s "$NN.flac" ] && {
		# prepare track tags, filter out empty tags, embed the rest
		cueprint -n $i -t 'ARRANGER=%A\nCOMPOSER=%C\nGENRE=%G\nMESSAGE=%M\nTRACKNUMBER=%n\nARTIST=%p\nTITLE=%t\nALBUM=%T\n' "$TEMPCUE" |egrep -v '=$' | metaflac --import-tags-from=- $NN.flac
		# rename NN.flac to "NN - TrackTitle.flac"
		mv $NN.flac "$NN - $(cueprint -n $i -t %t "$TEMPCUE").flac"
		}
	done
}

# Delete old file
delold() {
	case "$DELETE" in 
		"prompt" )
			echo -ne "\nDelete \"$FILE\"? "
			read -e DELPROMPT
			if [[ "$DELPROMPT" == "y" || "$DELPROMPT" == "Y" ]]; then
				DELETE=force
			fi
	;;
		"force" )
		rm -f "$TARGET" &> /dev/null
		echo -ne "deleted"
	;;
		* )
		echo -ne "kept"
	esac
}

search () {
	xx=0
	for TARGET in *
		do
			if [ -f "$TARGET" ]; then
				EXT=`echo "$TARGET" | sed -ne 's!^.*\.!!p' | tr '[:upper:]' '[:lower:]'` &> /dev/null
				BASE=`echo "$TARGET" | sed -e 's!\.[^.]*$!!'` &> /dev/null
				if [ "$EXT" = "$MYEXT" ]; then
					echo -n ".";
					[[ "x$SPLIT" == "x1" ]] || convert &> /dev/null
					CUE_FILE="$(findcuefile)"
					if [[ -n "$CUE_FILE" ]]; then
						TEMPCUE="/tmp/$PROG.$RANDOM.cue"
						cp "$CUE_FILE" "$TEMPCUE"
						recodecue &>/dev/null
						if [[ "x$SPLIT" == "x1" ]]; then
							convertandsplit
							embedtags
						fi
						sed s/"\.ape"/"\.flac"/ -i "$TEMPCUE"
						if echo "${CUE_FILE}" | grep -q "\.ape\.cue"; then
							cp "$TEMPCUE" "${CUE_FILE//.ape/.flac}"
						else
							cp "$TEMPCUE" "${CUE_FILE//.cue/.flac.cue}"
						fi
					fi
					xx=`expr $xx + 1`
					numfiles=`expr $numfiles + 1`
					
					delold
					rm -f "$TEMPCUE" &> /dev/null
				fi
			else
				if [[ $xx > 0 ]]; then
					echo " -> [$xx files converted]"
					xx=0
				fi
			fi
			
		if [ -d "$TARGET" ]; then
			zz=0
			while [ $zz != $deep ]
			do
				echo -n "| "
				zz=`expr $zz + 1`
			done
			if [ -L "$TARGET" ]; then
				echo "+---$TARGET" `ls -l $TARGET | sed 's/^.*'$TARGET' //'`
			else
				echo "+---$TARGET"
				if cd "$TARGET"; then
					deep=`expr $deep + 1`
					search
					numdirs=`expr $numdirs + 1`
				fi
			fi
		fi
		done
	cd ..
	if [ "$deep" ]; then
		swfi=1
	fi
	deep=`expr $deep - 1`
}

if [ "x$TARGET_DIRECTORY" == "x" ]; then
	cd `pwd`
elif [ -e "$TARGET_DIRECTORY" ]; then
	cd "$TARGET_DIRECTORY"
else
	echo "Path \"$TARGET_DIRECTORY\" not found"
	exit 0
fi

for i in ${prog_needed[@]}
do
	echo -n "Checking for $i..... "
	if which "$i" &> /dev/null; then
		echo "Yes"
	else
		echo "No"
		echo "Programm $i is not installed. Please install $i first"
		exit 0
	fi
done

echo
echo "ape2flac 0.1b"
echo
echo "bash script to convert files compressed by Monkey's Audio into FLAC files."
echo
echo "Converting all files in directory = `pwd` and recurse indefinitely."
echo
swfi=0
deep=0
numdirs=0
numfiles=0
zz=0
xx=0

while [ "$swfi" != 1 ]
do
	search
done
echo
echo "Summary:"
echo
echo "Total directories = $numdirs"
echo "Total files converted = $numfiles"
echo
exit 0
