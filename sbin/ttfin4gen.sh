#! /bin/bash
# TTF fonts installer for Gentoo.
#
# Idea by Mellon

print_help() {
echo "Usage:"
echo "       $(basename "$0") [-fo <fonts overlay> ] [-dd <distdir>] [-ev <ebuild version>] [-g] [-d <\"description\">] <path to fonts for install>"
echo "       $(basename "$0") [-h]"
echo
echo "  -fo     Path to local overlay that should contain fonts ebuilds."
echo "  -dd     Path to distfiles directory."
echo "  -pv     Package version. Default: 0.0.1."
echo "  -g      Do not install package, just generate it."
echo "  -d      Description for ebuild."
echo "  -h      Print this."
}

generate_distfile() {
	tar -C "${FONTSPARENTPATH}" -cjhf "${DISTDIR}/${FONTSDIR}${MY_PV}.tar.bz2" "${FONTSDIR}"
	chown root:portage "${DISTDIR}/${FONTSDIR}${MY_PV}.tar.bz2"
	chmod 664 "${DISTDIR}/${FONTSDIR}${MY_PV}.tar.bz2"
}

generate_ebuild() {

PN="${FONTSDIR}"
EBUILD="${FONTSOVERLAY}/media-fonts/${PN}/${PN}${MY_PV}.ebuild"

[[ -d "${FONTSOVERLAY}/media-fonts" ]] || mkdir "${FONTSOVERLAY}/media-fonts"
[[ -d "${FONTSOVERLAY}/media-fonts/${PN}" ]] || mkdir "${FONTSOVERLAY}/media-fonts/${PN}"

echo \
'# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit font
' > ${EBUILD}

: ${DESCRIPTION:="ttf fonts collection"}
echo "DESCRIPTION=\"${DESCRIPTION}\"" >> ${EBUILD}

echo \
'HOMEPAGE=""
SRC_URI="${P}.tar.bz2"

RESTRICT="fetch"

LICENSE="as-is"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 mips ppc ppc64 s390 sh sparc x86 x86-fbsd"
IUSE="X"

DEPEND=""
RDEPEND=""

S="${WORKDIR}/${PN}"
FONT_S="${WORKDIR}/${PN}"
FONT_SUFFIX="ttf"' >> ${EBUILD}
}

create_digests() {
	ebuild "$EBUILD" digest
}

emerging() {
	emerge media-fonts/${PN}
}

#==============================================================================

if [[ -f /etc/make.globals ]]; then 
	source /etc/make.globals || ( echo "Can not source /etc/make.globals"; exit 1)
else
	echo "Can not find /etc/make.globals"
	exit 1
fi

if
[[ -f /etc/make.conf ]]; then
	source /etc/make.conf || ( echo "Can not source /etc/make.conf"; exit 1)
else
	echo "Can not find /etc/make.conf"
	exit 1
fi

[[ -f /etc/ttfin4gen.conf ]] && source /etc/ttfin4gen.conf

ARGS="$*"
until [ -z "$1" ] ; do
        case "$1" in
                "-fo" )
                        [[ "x$3" != "x" ]] && [[ -d "$2" ]] && FONTSOVERLAY="$2"
                        shift
        ;;
                "-dd" )
                        [[ "x$3" != "x" ]] && [[ -d "$2" ]] && DISTDIR="$2"
                        shift
        ;;
                "-pv" )
                        [[ "x$3" != "x" ]] && MY_PV="-$2"
                        shift
        ;;
                "-g" )
                        [[ "x$2" != "x" ]] && GENERATEONLY="1"
        ;;
                "-d" )
                        [[ "x$3" != "x" ]] && DESCRIPTION="$2"
                        shift
        ;;
                "-h" )
                        print_help
                        exit 0
        ;;
                * )
                        [[ -d "$1" ]] && FONTSPATH="$1"
        ;;
        esac
        shift
done

if [[ "x${FONTSOVERLAY}" == "x" ]]; then 
	echo "Can not find fonts overlay"
	exit 1
fi

if [[ "x${FONTSPATH}" == "x" ]]; then 
	echo "Can not find path to fonts for install"
	exit 1
fi

FONTSPARENTPATH="$(dirname "${FONTSPATH}")"
FONTSDIR="$(basename "${FONTSPATH}")"
: ${MY_PV:="-0.0.1"}

generate_distfile
generate_ebuild
create_digests
echo "Package generated succesfully and ready to instlall"
[[ "x$GENERATEONLY" == "x1" ]] || emerging
