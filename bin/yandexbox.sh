#! /bin/bash

# Path to WebDAV collection directory:
export DAVFS_DIR="/mnt/fuse/dav/${USER}/yandex"
# Path to the mhddfs mount point:
export MHDDFS_DIR="/mnt/fuse/mhddfs/$USER/yandex"
# Path to the encfs mount point:
export ENCFS_DIR="/mnt/fuse/encfs/$USER/yandex"
# Relative path to the encrypted root on WebDAV storages:
export ENC_DIR="enc"
# Path to encfs config:
export ENCFS6_CONFIG="${HOME}/.encfs/yandex.xml"
# Command to obtain encfs pass:
export ENCFS_EXTPASS="cat ${HOME}/.encfs/yandex.pwd"

mount_fuse() {
	for i in "${DAVFS_DIR}"/*; do
		if mount "$i"; then
			echo "$i WebDAV storage has been mounted"
			[[ -d "$i/${ENC_DIR}" ]] || mkdir "$i/${ENC_DIR}"
		else
			echo "Failed to mount $i WebDAV storage"
			exit 1
		fi
	done
	if mhddfs $(echo $(mount | grep "${DAVFS_DIR}" | awk "{print \$3\"/${ENC_DIR}\"}")) "${MHDDFS_DIR}"
	then
		echo "Unated storage has been mounted"
	else
		echo "Failed to mount unated storage"
		exit 1
	fi
	if encfs --extpass="${ENCFS_EXTPASS}" "${MHDDFS_DIR}" "${ENCFS_DIR}"; then
		echo "Encrypted storage has been mounted"
	else
		echo "Failed to mount encrypted storage"
		exit 1
	fi
}

umount_fuse() {
	if grep -q "${MHDDFS_DIR}" /proc/mounts; then
		if fusermount -u "${MHDDFS_DIR}"; then
			echo "Unated storage has been unmounted"
		else
			echo "Failed to unmount unated storage"
			exit 1
		fi
	fi
	if grep -q "${ENCFS_DIR}" /proc/mounts; then
		if fusermount -u "${ENCFS_DIR}"; then
			echo "Encrypted storage has been unmounted"
		else
			echo "Failed to unmount encrypted storage"
			exit 1
		fi
	fi
	for i in $(mount | grep  "${DAVFS_DIR}" | awk '{print $3}'); do
		if umount "$i"; then
			echo "$i WebDAV storage has been unmounted"
		else
			echo "Failed to unmount $i WebDAV storage"
		fi
	done
}

show_help() {
	echo "Usage: $(basename "$0") <-m|-u|-h>"
	echo "	-m	Mount"
	echo "	-u	Unmount"
	echo "	-h	Show this help"
}

case "$1" in
	"-m" ) mount_fuse ;;
	"-u" ) umount_fuse ;;
	"-h" ) show_help ;;
	  *  ) echo "Usage: $(basename "$0") <-m|-u|-h>"
	  	exit 1 ;;
esac
