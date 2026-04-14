SHELL := /bin/bash
.PHONY: all clean kernel busybox rootfs initramfs

all: output/bzImage output/jenteck-initramfs.cpio.gz

output/bzImage output/jenteck-initramfs.cpio.gz: build/build.sh
	./build/build.sh all

kernel: build/build.sh
	./build/build.sh kernel

busybox: build/build.sh
	./build/build.sh busybox

rootfs: build/build.sh
	./build/build.sh rootfs

initramfs: build/build.sh
	./build/build.sh initramfs

clean:
	rm -rf output
