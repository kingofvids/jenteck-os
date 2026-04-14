#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/output"
BUILD_DIR="$OUTPUT_DIR/build"
DOWNLOAD_DIR="$ROOT_DIR/downloads"
ROOTFS_TEMPLATE_DIR="$ROOT_DIR/rootfs"

KERNEL_VERSION="6.8.12"
BUSYBOX_VERSION="1.36.1"
KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
BUSYBOX_TARBALL="busybox-${BUSYBOX_VERSION}.tar.bz2"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TARBALL}"
BUSYBOX_URL="https://busybox.net/downloads/${BUSYBOX_TARBALL}"

mkdir -p "$OUTPUT_DIR" "$BUILD_DIR" "$DOWNLOAD_DIR"

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command '$1' not found." >&2
    echo "Install the missing dependency and retry." >&2
    missing=1
  fi
}

check_header() {
  local header="$1"
  if ! printf '#include <%s>\nint main(){}\n' "$header" | gcc -x c - -o /dev/null >/dev/null 2>&1; then
    echo "ERROR: required C header <$header> not found." >&2
    echo "Install the appropriate development package and retry." >&2
    missing=1
  fi
}

check_kernel_dependencies() {
  missing=0
  for cmd in curl tar xz gzip make gcc git flex bison cpio bc; do
    check_command "$cmd"
  done
  check_header libelf.h
  check_header gelf.h
  if [[ $missing -ne 0 ]]; then
    echo >&2
    echo >&2 "Required packages on Debian/Ubuntu: build-essential flex bison libncurses-dev libssl-dev libelf-dev bc cpio xz-utils"
    exit 1
  fi
}

check_busybox_dependencies() {
  missing=0
  for cmd in curl tar xz gzip make gcc git cpio; do
    check_command "$cmd"
  done
  if [[ $missing -ne 0 ]]; then
    echo >&2
    echo >&2 "Required packages on Debian/Ubuntu: build-essential cpio xz-utils"
    exit 1
  fi
}

download_file() {
  local url="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    echo "Using existing $(basename "$path")"
    return
  fi
  echo "Downloading $(basename "$path")..."
  curl -L --fail -o "$path" "$url"
}

extract_kernel() {
  local target="$BUILD_DIR/linux-${KERNEL_VERSION}"
  if [[ ! -d "$target" ]]; then
    echo "Extracting Linux kernel source..."
    tar -C "$BUILD_DIR" -xJf "$DOWNLOAD_DIR/$KERNEL_TARBALL"
  fi
}

extract_busybox() {
  local target="$BUILD_DIR/busybox-${BUSYBOX_VERSION}"
  if [[ ! -d "$target" ]]; then
    echo "Extracting BusyBox source..."
    tar -C "$BUILD_DIR" -xjf "$DOWNLOAD_DIR/$BUSYBOX_TARBALL"
  fi
}

build_kernel() {
  extract_kernel
  pushd "$BUILD_DIR/linux-${KERNEL_VERSION}" > /dev/null
  echo "Configuring Linux kernel..."
  make defconfig
  echo "Building Linux kernel..."
  make -j"$(nproc)"
  cp -v arch/x86/boot/bzImage "$OUTPUT_DIR/bzImage"
  popd > /dev/null
}

build_busybox() {
  extract_busybox
  pushd "$BUILD_DIR/busybox-${BUSYBOX_VERSION}" > /dev/null
  echo "Configuring BusyBox..."
  make defconfig
  echo "Disabling BusyBox tc applet to avoid missing kernel traffic control headers..."
  ./scripts/config --disable TC
  make oldconfig >/dev/null 2>&1 || true
  echo "Building BusyBox..."
  make -j"$(nproc)"
  echo "Installing BusyBox into rootfs staging area..."
  make CONFIG_PREFIX="$OUTPUT_DIR/rootfs" install
  popd > /dev/null
}

prepare_rootfs() {
  echo "Preparing root filesystem..."
  rm -rf "$OUTPUT_DIR/rootfs"
  mkdir -p "$OUTPUT_DIR/rootfs"
  build_busybox

  mkdir -p "$OUTPUT_DIR/rootfs"/etc
  mkdir -p "$OUTPUT_DIR/rootfs"/proc
  mkdir -p "$OUTPUT_DIR/rootfs"/sys
  mkdir -p "$OUTPUT_DIR/rootfs"/tmp
  mkdir -p "$OUTPUT_DIR/rootfs"/var
  mkdir -p "$OUTPUT_DIR/rootfs"/mnt
  mkdir -p "$OUTPUT_DIR/rootfs"/root
  mkdir -p "$OUTPUT_DIR/rootfs"/dev

  cp -a "$ROOTFS_TEMPLATE_DIR/etc"/* "$OUTPUT_DIR/rootfs/etc/"
  install -m 755 "$ROOTFS_TEMPLATE_DIR/init" "$OUTPUT_DIR/rootfs/init"
  chmod +x "$OUTPUT_DIR/rootfs/init"
}

create_initramfs() {
  echo "Creating initramfs image..."
  pushd "$OUTPUT_DIR/rootfs" > /dev/null
  find . | cpio -H newc -o | gzip -9 > "$OUTPUT_DIR/jenteck-initramfs.cpio.gz"
  popd > /dev/null
}

show_help() {
  cat <<'EOF'
Usage: build.sh [all|kernel|busybox|rootfs|initramfs|clean]

Targets:
  all       - download sources, build kernel, BusyBox, rootfs, and initramfs
  kernel    - build the Linux kernel only
  busybox   - build BusyBox only
  rootfs    - assemble the root filesystem
  initramfs - package the initramfs image
  clean     - remove generated artifacts
EOF
}

main() {
  local target="${1-}"
  case "$target" in
    ""|all)
      check_kernel_dependencies
      download_file "$KERNEL_URL" "$DOWNLOAD_DIR/$KERNEL_TARBALL"
      download_file "$BUSYBOX_URL" "$DOWNLOAD_DIR/$BUSYBOX_TARBALL"
      build_kernel
      prepare_rootfs
      create_initramfs
      ;;
    kernel)
      check_kernel_dependencies
      download_file "$KERNEL_URL" "$DOWNLOAD_DIR/$KERNEL_TARBALL"
      build_kernel
      ;;
    busybox)
      check_busybox_dependencies
      download_file "$BUSYBOX_URL" "$DOWNLOAD_DIR/$BUSYBOX_TARBALL"
      build_busybox
      ;;
    rootfs)
      check_busybox_dependencies
      download_file "$BUSYBOX_URL" "$DOWNLOAD_DIR/$BUSYBOX_TARBALL"
      prepare_rootfs
      ;;
    initramfs)
      create_initramfs
      ;;
    clean)
      rm -rf "$OUTPUT_DIR"
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
}

main "$@"
