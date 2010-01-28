#!/bin/bash +x

OVERLAY="/usr/portage-overlay/local"
PORTDIR="/usr/portage/"

if [[ -z $1 ]]; then
	echo "I need at least one argument in category/package format."
	exit 1
fi

cd ${OVERLAY} || {
	echo "Could not chdir to ${OVERLAY}, exiting."
	exit 7
}

for ARG in "$@"; do
	CAT=${ARG/\/*/}
	PKG=${ARG/*\//}

	if [[ "${CAT}/${PKG}" != ${ARG} ]]; then
		echo "Parameters not quite right (${CAT}/${PKG}), skipping..."
		continue
	fi

	if [[ ! -d ${PORTDIR}/${CAT}/${PKG} ]]; then
		echo "Could not find package ${CAT}/${PKG} to overlay, skipping..."
		continue
	fi

	if [[ ! -d ${CAT} ]]; then
		mkdir ${CAT} || {
			echo "Could not makedir ${DIR}, skipping."
			continue
		}
	fi

	if [[ -d ${CAT}/${PKG} ]]; then
		echo "Overlay directory ${CAT}/${PKG} exists, not doing anything!"
		continue
	fi

	cp -a ${PORTDIR}/${CAT}/${PKG} ${OVERLAY}/${CAT}/ || {
		echo "Something went wrong with copying the files."
		echo "Fix your mess in ${OVERLAY}/${CAT}/${PKG} by hand."
	}
done
