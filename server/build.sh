#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-x86_64}"
[[ "$ARCH" != "x86_64" && "$ARCH" != "i686" ]] && {
    echo "Usage: $0 [x86_64|i686]"; exit 1
}

JOBS="${JOBS:-$(nproc)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build/${ARCH}"
ROOTFS="${BUILD_DIR}/rootfs"
ISO_STAGING="${BUILD_DIR}/iso"
OUTPUT="${SCRIPT_DIR}/output"

source "${SCRIPT_DIR}/scripts/versions.sh"
source "${SCRIPT_DIR}/scripts/functions.sh"
source "${SCRIPT_DIR}/scripts/01-toolchain.sh"
source "${SCRIPT_DIR}/scripts/02-base-system.sh"
source "${SCRIPT_DIR}/scripts/03-kernel.sh"
source "${SCRIPT_DIR}/scripts/04-bootloader.sh"
source "${SCRIPT_DIR}/scripts/05-flatpak.sh"
source "${SCRIPT_DIR}/scripts/06-jenfetch-config.sh"
source "${SCRIPT_DIR}/scripts/08-initramfs-iso.sh"

START_PHASE="${START_PHASE:-1}"

banner "Jenteck OS Builder"
echo -e "  Arch:   ${ARCH}\n  Jobs:   ${JOBS}\n  Output: ${OUTPUT}\n"

run_phase() {
    local num="$1" name="$2" fn="$3"
    if (( num >= START_PHASE )); then
        $fn
    else
        info "Skipping Phase ${num} (${name})"
    fi
}

check_host_deps; prepare_dirs
run_phase 1 "Toolchain"   build_toolchain
run_phase 2 "Base System" build_base_system
run_phase 3 "Kernel"      install_kernel
run_phase 4 "Bootloader"  install_bootloader
run_phase 5 "Flatpak"     install_flatpak
run_phase 6 "jenfetch"    install_jenfetch
run_phase 7 "Config"      install_jenteck_config
run_phase 8 "Initramfs"   build_initramfs
run_phase 9 "ISO"         assemble_iso

banner "Done → output/jenteck-os-${ARCH}.iso"
echo "  Flash:  sudo dd if=output/jenteck-os-${ARCH}.iso of=/dev/sdX bs=4M status=progress"
echo "  QEMU:   qemu-system-${ARCH} -m 2G -cdrom output/jenteck-os-${ARCH}.iso -boot d"
