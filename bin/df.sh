#! /bin/bash

TMP_DIR="/dev/shm/$USER/awesome"
CMD="df $*"
name="$(basename $0)"

[ -d "$TMP_DIR" ] || mkdir -p "$TMP_DIR"

if ! pgrep -F "$TMP_DIR/$name.pid" &> /dev/null; then
	{
		$CMD > "$TMP_DIR/$name.tmp" 2> /dev/null
		mv "$TMP_DIR/$name.tmp" "$TMP_DIR/$name.out"
	} &
	echo $! > "$TMP_DIR/$name.pid"
fi

cat "$TMP_DIR/$name.out" 2> /dev/null
