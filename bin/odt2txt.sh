#! /bin/sh

unzip -p "$1" content.xml |\
xmlstarlet sel -N text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" -T -t -m '//text:p' -v . -n
#tr "<" "\012" | grep -i '^text' | cut '-d>' -f2- | perl -e "while (<>) {s/&apos;/'/g; print}"

