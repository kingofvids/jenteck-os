#!/usr/bin/env bash
# =============================================================================
#  Phase 4 — GRUB Bootloader
#  Creates both:
#    • BIOS boot image  (grub/i386-pc)
#    • UEFI boot image  (EFI/BOOT/BOOTX64.EFI or BOOTIA32.EFI)
#  The ISO is crafted with xorriso so it boots both ways.
# =============================================================================

install_bootloader() {
    banner "Phase 4 — Installing GRUB Bootloader"

    local GRUB_DIR="${ISO_STAGING}/boot/grub"
    mkdir -p "${GRUB_DIR}/fonts"
    mkdir -p "${ISO_STAGING}/EFI/BOOT"

    # ── GRUB config (menus for both live and install) ─────────────────────
    cat > "${GRUB_DIR}/grub.cfg" << 'EOF'
set default=0
set timeout=5

# Jenteck OS colour scheme
set color_normal=cyan/black
set color_highlight=white/blue

insmod all_video
insmod gfxterm
terminal_output gfxterm

# ── ASCII logo in menu ──────────────────────────────────────────────────
echo ""
echo "     ██╗███████╗███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗"
echo "     ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║ ██╔╝"
echo "     ██║█████╗  ██╔██╗ ██║   ██║   █████╗  ██║     █████╔╝ "
echo "██   ██║██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔═██╗ "
echo "╚█████╔╝███████╗██║ ╚████║   ██║   ███████╗╚██████╗██║  ██╗"
echo " ╚════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝"
echo ""
echo "         Jenteck OS — Born from scratch."
echo ""

menuentry "Jenteck OS (Live)" --class jenteck {
    insmod gzio
    insmod part_gpt
    insmod part_msdos
    insmod fat
    insmod iso9660
    insmod squash4
    linux  /boot/vmlinuz boot=live quiet splash loglevel=3 \
           rd.systemd.show_status=false vt.global_cursor_default=0
    initrd /boot/initramfs.img
}

menuentry "Jenteck OS (Live — verbose)" --class jenteck {
    insmod gzio
    linux  /boot/vmlinuz boot=live
    initrd /boot/initramfs.img
}

menuentry "Jenteck OS (RAM)" --class jenteck {
    insmod gzio
    linux  /boot/vmlinuz boot=live toram quiet splash
    initrd /boot/initramfs.img
}

menuentry "Install Jenteck OS (TUI)" --class jenteck {
    insmod gzio
    linux  /boot/vmlinuz boot=live jenteck.install=1 quiet
    initrd /boot/initramfs.img
}

menuentry "Memory Test (memtest86+)" --class memtest {
    linux16 /boot/memtest86+
}

menuentry "Firmware Setup (UEFI)" --class settings {
    fwsetup
}
EOF

    # ── Embed GRUB modules for a standalone EFI image ────────────────────
    info "Building GRUB EFI image …"
    local GRUB_MODS="part_gpt part_msdos fat iso9660 squash4 normal boot \
        linux echo all_video gfxmenu gfxterm gfxterm_background \
        loadenv loopback minicmd ext2 search test true gzio"

    if [[ "$ARCH" == "x86_64" ]]; then
        grub-mkimage \
            --format=x86_64-efi \
            --output="${ISO_STAGING}/EFI/BOOT/BOOTX64.EFI" \
            --prefix="/boot/grub" \
            ${GRUB_MODS}

        # Also provide ia32 EFI for older UEFI firmware on 64-bit machines
        grub-mkimage \
            --format=i386-efi \
            --output="${ISO_STAGING}/EFI/BOOT/BOOTIA32.EFI" \
            --prefix="/boot/grub" \
            ${GRUB_MODS}
    else
        # 32-bit build: i386-efi
        grub-mkimage \
            --format=i386-efi \
            --output="${ISO_STAGING}/EFI/BOOT/BOOTIA32.EFI" \
            --prefix="/boot/grub" \
            ${GRUB_MODS}
    fi

    # ── GRUB BIOS core image ──────────────────────────────────────────────
    info "Building GRUB BIOS core image …"
    grub-mkimage \
        --format=i386-pc \
        --output="${ISO_STAGING}/boot/grub/core.img" \
        --prefix="/boot/grub" \
        biosdisk iso9660 ${GRUB_MODS}

    # Copy BIOS GRUB modules
    cp -r /usr/lib/grub/i386-pc "${GRUB_DIR}/"

    # ── EFI FAT image (required by UEFI spec) ────────────────────────────
    info "Creating EFI system partition image …"
    local ESP="${ISO_STAGING}/boot/efi.img"
    dd if=/dev/zero of="${ESP}" bs=1M count=4 2>/dev/null
    mkfs.fat -F 16 "${ESP}" >/dev/null
    local MNT; MNT=$(mktemp -d)
    sudo mount "${ESP}" "${MNT}"
    sudo mkdir -p "${MNT}/EFI/BOOT"
    if [[ "$ARCH" == "x86_64" ]]; then
        sudo cp "${ISO_STAGING}/EFI/BOOT/BOOTX64.EFI" "${MNT}/EFI/BOOT/"
    fi
    sudo cp "${ISO_STAGING}/EFI/BOOT/BOOTIA32.EFI" "${MNT}/EFI/BOOT/"
    sudo umount "${MNT}"
    rmdir "${MNT}"

    # Copy memtest86+ if available on host
    [[ -f /boot/memtest86+.bin ]] && \
        cp /boot/memtest86+.bin "${ISO_STAGING}/boot/memtest86+"

    info "✔ Bootloader ready."
}
