#!/usr/bin/env bash
# =============================================================================
#  Jenteck OS — Master Build Script
#  Builds a from-scratch (LFS-style) live ISO for:
#    • x86_64  (UEFI + Legacy BIOS)
#    • i686    (Legacy BIOS only)
#  Host requirement: Debian/Ubuntu with sudo
#
#  Usage:
#    ./build.sh             # defaults to x86_64
#    ./build.sh x86_64
#    ./build.sh i686
#    JOBS=8 ./build.sh x86_64
#    START_PHASE=7 ./build.sh x86_64   # resume from a phase
# =============================================================================
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

# Source all phase modules
source "${SCRIPT_DIR}/scripts/versions.sh"
source "${SCRIPT_DIR}/scripts/functions.sh"
source "${SCRIPT_DIR}/scripts/01-toolchain.sh"
source "${SCRIPT_DIR}/scripts/02-base-system.sh"
source "${SCRIPT_DIR}/scripts/03-kernel.sh"
source "${SCRIPT_DIR}/scripts/04-bootloader.sh"
source "${SCRIPT_DIR}/scripts/05-flatpak.sh"
source "${SCRIPT_DIR}/scripts/06-jenfetch-config.sh"
source "${SCRIPT_DIR}/scripts/07a-x11-stack.sh"
source "${SCRIPT_DIR}/scripts/07b-xfce4.sh"
source "${SCRIPT_DIR}/scripts/08-initramfs-iso.sh"

START_PHASE="${START_PHASE:-1}"

banner "Jenteck OS Builder"
echo -e "  Arch:   ${ARCH}"
echo -e "  Jobs:   ${JOBS}"
echo -e "  Output: ${OUTPUT}"
echo -e "  Start:  Phase ${START_PHASE}"
echo ""

run_phase() {
    local num="$1" name="$2" fn="$3"
    if (( num >= START_PHASE )); then
        banner "Phase ${num} — ${name}"
        $fn
    else
        info "Skipping Phase ${num} (${name}) — START_PHASE=${START_PHASE}"
    fi
}

check_host_deps
prepare_dirs

run_phase  1  "Cross-Toolchain"            build_toolchain
run_phase  2  "Base System"                build_base_system
run_phase  3  "Linux Kernel"               install_kernel
run_phase  4  "Bootloader (GRUB)"          install_bootloader
run_phase  5  "Flatpak"                    install_flatpak
run_phase  6  "jenfetch"                   install_jenfetch
run_phase  7  "Branding & Init Config"     install_jenteck_config
run_phase  8  "X11 Display Stack"          build_x11_stack
run_phase  9  "XFCE4 Desktop"             build_xfce4
run_phase 10  "LightDM Display Manager"   build_lightdm
run_phase 11  "XFCE4 Theme & Defaults"    configure_xfce4
run_phase 12  "Graphical Installer"        install_jenteck_installer
run_phase 13  "Initramfs"                  build_initramfs
run_phase 14  "Assemble ISO"               assemble_iso

banner "Build Complete"
echo -e "  ${GRN}✔${RST}  output/jenteck-os-${ARCH}.iso"
echo ""
echo "  Flash to USB:   sudo dd if=output/jenteck-os-${ARCH}.iso of=/dev/sdX bs=4M status=progress"
echo "  Test (UEFI):    qemu-system-${ARCH} -m 2G -bios /usr/share/ovmf/OVMF.fd -cdrom output/jenteck-os-${ARCH}.iso -boot d"
echo "  Test (BIOS):    qemu-system-${ARCH} -m 2G -cdrom output/jenteck-os-${ARCH}.iso -boot d"
echo ""
