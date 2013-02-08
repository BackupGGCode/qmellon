#! /bin/bash

# until [[ "x$i" == "x1" ]]; do
# 	cairo-compmgr && i=1
# done

run_once() {
pgrep -f -u "${USER}" -x "$1" &> /dev/null || $@
}

run_once kbdd
run_once compton -CcfF -D "6" -l "-5" -t "-5" -r "3" -o "0.3" -b &> /dev/null
run_once udisks-glue -c ~/.config/awesome/.udisks-glue.conf
