#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_IMAGE="$ROOT_DIR/output/bzImage"
INITRAMFS="$ROOT_DIR/output/jenteck-initramfs.cpio.gz"

if [[ ! -f "$KERNEL_IMAGE" || ! -f "$INITRAMFS" ]]; then
  echo "Build the kernel and initramfs first with: make all"
  exit 1
fi

exec qemu-system-x86_64 \
  -kernel "$KERNEL_IMAGE" \
  -initrd "$INITRAMFS" \
  -append "console=ttyS0 root=/dev/ram0 rw init=/init" \
  -nographic \
  -m 512
