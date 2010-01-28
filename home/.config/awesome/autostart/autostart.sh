#! /bin/bash

until [[ "x$i" == "x1" ]]; do
	cairo-compmgr && i=1
done
