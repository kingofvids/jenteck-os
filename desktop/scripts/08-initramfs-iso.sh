#!/usr/bin/env bash
# =============================================================================
#  Phase 8 — Initramfs
#  Builds a minimal initramfs that:
#    1. Mounts the live squashfs via OverlayFS
#    2. Hands off to the real /sbin/init
# =============================================================================

build_initramfs() {
    banner "Phase 8 — Building Initramfs"

    local INITRD_DIR="${BUILD_DIR}/initramfs"
    rm -rf "${INITRD_DIR}"
    mkdir -p "${INITRD_DIR}"/{bin,sbin,lib,lib64,proc,sys,dev,run,mnt/{live,lower,upper,work},newroot}

    # ── Copy BusyBox (static) into initramfs ────────────────────────────────
    cp "${ROOTFS}/bin/busybox" "${INITRD_DIR}/bin/busybox"
    # Create symlinks for tools we need in early boot
    for tool in sh mount umount mkdir mknod switch_root sleep echo ls \
                grep awk modprobe insmod lsmod cat find; do
        ln -sf busybox "${INITRD_DIR}/bin/${tool}"
    done

    # ── init script ──────────────────────────────────────────────────────────
    cat > "${INITRD_DIR}/init" << 'EOF'
#!/bin/sh
# Jenteck OS initramfs init

export PATH=/bin:/sbin

mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev || mknod /dev/null c 1 3

# Load common FS / block drivers
for mod in squashfs overlay loop isofs ext4 vfat ahci xhci_hcd ehci_hcd \
           usb_storage uas sd_mod sr_mod nvme virtio_blk; do
    modprobe "$mod" 2>/dev/null
done

# Find and mount the live medium
LIVE_MEDIUM=""
for dev in /dev/sr0 /dev/sr1 /dev/sda /dev/sdb /dev/sdc /dev/vda; do
    if mount -o ro "$dev" /mnt/live 2>/dev/null; then
        if [ -f /mnt/live/live/filesystem.squashfs ]; then
            LIVE_MEDIUM="$dev"
            break
        fi
        umount /mnt/live 2>/dev/null
    fi
done

[ -z "$LIVE_MEDIUM" ] && {
    echo "ERROR: Cannot find Jenteck OS live medium!"
    echo "Dropping to emergency shell …"
    exec /bin/sh
}

# Mount squashfs as lower layer
mount -t squashfs -o ro,loop /mnt/live/live/filesystem.squashfs /mnt/lower

# RAM overlay so the live system is writable
mount -t tmpfs tmpfs /mnt/work
mkdir -p /mnt/work/upper /mnt/work/workdir
mount -t overlay overlay \
    -o lowerdir=/mnt/lower,upperdir=/mnt/work/upper,workdir=/mnt/work/workdir \
    /newroot

# Move mounts into new root
mount --move /proc  /newroot/proc  2>/dev/null
mount --move /sys   /newroot/sys   2>/dev/null
mount --move /dev   /newroot/dev   2>/dev/null

exec switch_root /newroot /sbin/init
EOF
    chmod +x "${INITRD_DIR}/init"

    # ── Pack into cpio.gz ────────────────────────────────────────────────────
    info "Packing initramfs …"
    ( cd "${INITRD_DIR}" && find . | cpio -H newc -o --quiet | gzip -9 ) \
        > "${ISO_STAGING}/boot/initramfs.img"

    info "✔ Initramfs → boot/initramfs.img ($(du -sh "${ISO_STAGING}/boot/initramfs.img" | cut -f1))"
}

# =============================================================================
#  Phase 9 — Assemble ISO
# =============================================================================

assemble_iso() {
    banner "Phase 9 — Assembling ISO"
    mkdir -p "${ISO_STAGING}/live" "${OUTPUT}"

    # ── Create squashfs of the rootfs ────────────────────────────────────────
    info "Creating squashfs (this may take a while) …"
    mksquashfs "${ROOTFS}" "${ISO_STAGING}/live/filesystem.squashfs" \
        -comp xz -Xbcj x86 \
        -noappend -no-progress \
        -e "${BUILD_DIR}" \
        -e proc -e sys -e dev -e run -e tmp
    info "Squashfs size: $(du -sh "${ISO_STAGING}/live/filesystem.squashfs" | cut -f1)"

    # ── Assemble ISO with xorriso (UEFI + BIOS hybrid) ─────────────────────
    local ISO_OUT="${OUTPUT}/jenteck-os-${ARCH}.iso"
    info "Running xorriso …"

    xorriso -as mkisofs \
        -volid "JENTECK_OS_1_0" \
        -isohybrid-mbr /usr/lib/grub/i386-pc/isohdpfx.bin \
        -c boot/grub/boot.cat \
        -b boot/grub/core.img \
            -no-emul-boot \
            -boot-load-size 4 \
            -boot-info-table \
        -eltorito-alt-boot \
        -e boot/efi.img \
            -no-emul-boot \
            -isohybrid-gpt-basdat \
        -append_partition 2 0xef "${ISO_STAGING}/boot/efi.img" \
        -output "${ISO_OUT}" \
        "${ISO_STAGING}"

    info "✔ ISO complete!"
    info "  Path: ${ISO_OUT}"
    info "  Size: $(du -sh "${ISO_OUT}" | cut -f1)"

    # ── Verify ───────────────────────────────────────────────────────────────
    if command -v file &>/dev/null; then
        file "${ISO_OUT}"
    fi
}
