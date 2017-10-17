#set -v
#set -x

DIR=$(dirname "$0")

require_init() {
	if [ "$1" != "init" -a "$1" != "init_32" ]; then
		echo "Argument must be init or init_32"
		exit 1
	fi
}

unpack() {
	require_init "$1"
	echo "Unpack $1"
	
	[ ! -d "$DIR/.build" ] && mkdir "$DIR/.build"
	cp "/var/www/fog/service/ipxe/$1.xz" "$DIR/.build/$1.xz"

	if [ ! -f "$DIR/.build/original_$1.xz" ]; then
		cp "$DIR/.build/$1.xz" "$DIR/.build/original_$1.xz"
	fi
	
	xz -d "$DIR/.build/$1.xz" || exit 1
	mkdir "$DIR/.build/$1_mountdir"
	mount -o loop "$DIR/.build/$1" "$DIR/.build/$1_mountdir"
}

modify() {
	require_init "$1"
	echo "Modify $1"
	
	if [ ! -f "$DIR/.build/$1_mountdir/etc/init.d/S40network" ]; then
		"$1 should be mounted"
		exit 1
	fi
	
	cp "$DIR/etc/init.d/S40network" "$DIR/.build/$1_mountdir/etc/init.d/S40network"
	cp "$DIR/etc/init.d/K40network" "$DIR/.build/$1_mountdir/etc/init.d/K40network"
	cp "$DIR/usr/share/udhcpc/default.script" "$DIR/.build/$1_mountdir/usr/share/udhcpc/default.script"
}

pack() {
	require_init "$1"
	echo "Pack $1"

	if [ ! -f "$DIR/.build/$1" ]; then
		"$1 doesn't exist"
		exit 1
	fi

	
	umount "$DIR/.build/$1_mountdir"
	rmdir "$DIR/.build/$1_mountdir"
	xz -C crc32 -9 "$DIR/.build/$1"
}

copy() {
	require_init "$1"
	echo "Copy $1"
	cp "$DIR/.build/$1.xz" "/var/www/fog/service/ipxe/$1.xz"
}

cleanup() {
	require_init "$1"
	echo "Cleanup $1"
	rm "$DIR/.build/$1.xz"
}

update() {
	require_init "$1"
	echo "Updating $1"
	
	unpack	$1
	modify	$1
	pack	$1
	copy	$1
	cleanup	$1
	
	echo ""
}

update	init
update	init_32
