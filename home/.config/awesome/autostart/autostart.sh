#! /bin/bash

# until [[ "x$i" == "x1" ]]; do
# 	cairo-compmgr && i=1
# done

run_once() {
pgrep -f -u "${USER}" -x "$1" &> /dev/null || $@
}

run_once kbdd
run_once xcompmgr -CcfF -D "6" -l "-5" -t "-5" -r "3" -o "0.3" &> /dev/null &
