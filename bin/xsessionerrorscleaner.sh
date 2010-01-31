#! /bin/bash

while true ; do
	inotifywait -e modify ~/.xsession-errors &> /dev/null
	[[ "$(stat -c %s ~/.xsession-errors)" -ge "52428800" ]] && echo > ~/.xsession-errors
done
