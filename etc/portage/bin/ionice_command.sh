#!/bin/sh
# $1 must be the portage PID

cgclassify -g cpu,blkio:portage --sticky ${1} &> /dev/null
ionice -c 3 -p ${1}
