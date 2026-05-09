#!/usr/bin/env bash
# =============================================================================
#  Phase 3 — Linux Kernel
#  Builds a minimal but hardware-compatible kernel for x86_64 and i686.
#  Enables: ext4, squashfs, overlayfs, USB, AHCI, NVMe, VirtIO, framebuffer.
# =============================================================================

install_kernel() {
    banner "Phase 3 — Building Linux Kernel ${LINUX_VER} (${ARCH})"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"

    local KARCH; [[ "$ARCH" == "x86_64" ]] && KARCH="x86_64" || KARCH="i386"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}-"

    pushd "${WORK}/linux-${LINUX_VER}" >/dev/null

    # Start from a clean slate
    make ARCH="${KARCH}" CROSS_COMPILE="${CROSS}" mrproper

    # Use x86_64 or i386 defconfig then customise
    make ARCH="${KARCH}" CROSS_COMPILE="${CROSS}" defconfig

    # ── Kernel config overrides (append to .config, then olddefconfig) ───────
    cat >> .config << 'KCONFIG'
# Jenteck OS kernel options

# Filesystems
CONFIG_EXT4_FS=y
CONFIG_SQUASHFS=y
CONFIG_SQUASHFS_XATTR=y
CONFIG_SQUASHFS_XZ=y
CONFIG_OVERLAY_FS=y
CONFIG_VFAT_FS=y
CONFIG_FAT_FS=y
CONFIG_TMPFS=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y

# Block devices
CONFIG_ATA=y
CONFIG_ATA_PIIX=y
CONFIG_SATA_AHCI=y
CONFIG_BLK_DEV_SD=y
CONFIG_BLK_DEV_SR=y
CONFIG_SCSI=y
CONFIG_SCSI_SCAN_ASYNC=y
CONFIG_NVME_CORE=y
CONFIG_BLK_DEV_NVME=y

# USB
CONFIG_USB=y
CONFIG_USB_XHCI_HCD=y
CONFIG_USB_EHCI_HCD=y
CONFIG_USB_OHCI_HCD=y
CONFIG_USB_UAS=y
CONFIG_USB_STORAGE=y

# VirtIO (for VM testing)
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_NET=y
CONFIG_VIRTIO_CONSOLE=y

# Network
CONFIG_NET=y
CONFIG_INET=y
CONFIG_ETHERNET=y
CONFIG_E1000=y
CONFIG_E1000E=y
CONFIG_R8169=y

# Wi-Fi (mac80211 stack)
CONFIG_MAC80211=y
CONFIG_CFG80211=y
CONFIG_IWLWIFI=y
CONFIG_IWLMVM=y
CONFIG_RTL8192CE=y
CONFIG_RTL8192SE=y
CONFIG_RTW88=y
CONFIG_ATH9K=y
CONFIG_ATH10K=y
CONFIG_ATH10K_PCI=y

# Framebuffer / display
CONFIG_FB=y
CONFIG_FB_VESA=y
CONFIG_FB_EFI=y
CONFIG_DRM=y
CONFIG_DRM_SIMPLEDRM=y
CONFIG_FRAMEBUFFER_CONSOLE=y

# EFI support
CONFIG_EFI=y
CONFIG_EFI_STUB=y
CONFIG_EFI_VARS=y

# Init/namespace
CONFIG_NAMESPACES=y
CONFIG_USER_NS=y
CONFIG_CGROUPS=y
CONFIG_MEMCG=y
CONFIG_SCHED_AUTOGROUP=y

# Misc
CONFIG_EXPERT=n
CONFIG_PRINTK=y
CONFIG_BUG=y
CONFIG_MULTIUSER=y
CONFIG_SHMEM=y
CONFIG_SYSVIPC=y
KCONFIG

    make ARCH="${KARCH}" CROSS_COMPILE="${CROSS}" olddefconfig

    # Build
    make ARCH="${KARCH}" CROSS_COMPILE="${CROSS}" -j"${JOBS}" bzImage modules

    # Install
    make ARCH="${KARCH}" CROSS_COMPILE="${CROSS}" \
        INSTALL_MOD_PATH="${ROOTFS}" modules_install

    cp "arch/x86/boot/bzImage" "${ROOTFS}/boot/vmlinuz-${LINUX_VER}"
    cp ".config"                "${ROOTFS}/boot/config-${LINUX_VER}"
    cp "System.map"             "${ROOTFS}/boot/System.map-${LINUX_VER}"

    # Also copy to ISO staging for bootloader
    cp "arch/x86/boot/bzImage" "${ISO_STAGING}/boot/vmlinuz"

    popd >/dev/null
    info "✔ Kernel installed → /boot/vmlinuz-${LINUX_VER}"
}
