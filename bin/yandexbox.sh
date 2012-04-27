#! /bin/bash

export  ENCFS6_CONFIG="${HOME}/.encfs/yandex.xml"

mount_fuse() {
	for i in /mnt/fuse/dav/${USER}/yandex/*; do
		if mount "$i"; then
			echo "$i WebDAV storage has been mounted"
			[[ -d "$i/enc" ]] || mkdir "$i/enc"
		else
			echo "Failed to mount $i WebDAV storage"
			exit 1
		fi
	done
	if mhddfs $(echo $(mount | grep "/mnt/fuse/dav/${USER}/yandex" | awk '{print $3"/enc"}')) \
		"/mnt/fuse/mhddfs/$USER/yandex/"
	then
		echo "Unated storage has been mounted"
	else
		echo "Failed to mount unated storage"
		exit 1
	fi
	if encfs --extpass="cat $HOME/.encfs/yandex.pwd" "/mnt/fuse/mhddfs/$USER/yandex/" "/mnt/fuse/encfs/$USER/yandex/"; then
		echo "Encrypted storage has been mounted"
	else
		echo "Failed to mount encrypted storage storage"
		exit 1
	fi
}
umount_fuse() {
	if grep -q "/mnt/fuse/mhddfs/$USER/yandex" /proc/mounts; then
		if fusermount -u /mnt/fuse/mhddfs/$USER/yandex; then
			echo "Unated storage has been unmounted"
		else
			echo "Failed to unmount unated storage"
			exit 1
		fi
	fi
	if grep -q "/mnt/fuse/encfs/${USER}/yandex" /proc/mounts; then
		if fusermount -u /mnt/fuse/encfs/$USER/yandex; then
			echo "Encrypted storage has been unmounted"
		else
			echo "Failed to unmount encrypted storage"
			exit 1
		fi
	fi
	for i in $(mount | grep "/mnt/fuse/dav/${USER}/yandex" | awk '{print $3}'); do
		if umount "$i"; then
			echo "$i WebDAV storage has been unmounted"
		else
			echo "Failed to unmount $i WebDAV storage"
		fi
	done
}

case "$1" in
	"-m" ) mount_fuse ;;
	"-u" ) umount_fuse ;;
	"-h" ) echo "Usage: $(basename "$0") <-m|-u|-h>"
		echo "	-m	Mount"
		echo "	-u	Unmount"
		echo "	-h	Show this help"
	;;
	  *  ) exit 1 ;;
esac
