#!/usr/bin/env bash
# =============================================================================
#  Phase 6 — jenfetch + Jenteck OS Branding
# =============================================================================

install_jenfetch() {
    banner "Phase 6 — Installing jenfetch"

    # ── Install jenfetch binary ───────────────────────────────────────────
    install -Dm755 "${SCRIPT_DIR}/rootfs-overlay/usr/bin/jenfetch" \
                   "${ROOTFS}/usr/bin/jenfetch"
    info "jenfetch installed to /usr/bin/jenfetch"
}

install_jenteck_config() {
    banner "Phase 7 — Jenteck OS Branding & Configuration"

    # ── /etc/jenteck-release ─────────────────────────────────────────────
    cat > "${ROOTFS}/etc/jenteck-release" << EOF
NAME="Jenteck OS"
VERSION="1.0"
VERSION_ID="1.0"
ID=jenteck
PRETTY_NAME="Jenteck OS 1.0"
HOME_URL="https://jenteck.co.uk"
SUPPORT_URL="https://github.com/kingofvids/jenteck-os"
BUG_REPORT_URL="https://github.com/kingofvids/jenteck-os/issues"
ARCH="${ARCH}"
BUILD_DATE="$(date -u +%Y-%m-%d)"
EOF

    # /etc/os-release → same file
    ln -sf jenteck-release "${ROOTFS}/etc/os-release"

    # ── /etc/hostname ────────────────────────────────────────────────────
    echo "jenteck" > "${ROOTFS}/etc/hostname"

    # ── /etc/hosts ───────────────────────────────────────────────────────
    cat > "${ROOTFS}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   jenteck
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

    # ── MOTD ─────────────────────────────────────────────────────────────
    cat > "${ROOTFS}/etc/motd" << 'EOF'

  ╔══════════════════════════════════════════════╗
  ║                                              ║
  ║   Welcome to  J E N T E C K   O S            ║
  ║   Born from scratch. Built for you.          ║
  ║                                              ║
  ║   Run  jenfetch  for system info             ║
  ║   Run  flatpak install flathub <app>         ║
  ║        to install applications               ║
  ║                                              ║
  ╚══════════════════════════════════════════════╝

EOF

    # ── /etc/profile ─────────────────────────────────────────────────────
    cat > "${ROOTFS}/etc/profile" << 'EOF'
# Jenteck OS /etc/profile
export PATH=/usr/bin:/usr/sbin:/bin:/sbin
export HOME="${HOME:-/root}"
export TERM="${TERM:-linux}"
export LANG="en_GB.UTF-8"

# Show jenfetch on login (suppress in non-interactive shells)
[[ -z "$JENFETCH_SHOWN" && "$-" == *i* ]] && {
    export JENFETCH_SHOWN=1
    jenfetch
}

# Useful aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias fp='flatpak'
alias fpinstall='flatpak install flathub'
alias fpsearch='flatpak search'
alias fplist='flatpak list'
alias fprun='flatpak run'
EOF

    # ── /etc/issue ───────────────────────────────────────────────────────
    cat > "${ROOTFS}/etc/issue" << 'EOF'
Jenteck OS 1.0  \r  \l
EOF

    # ── Simple /sbin/init (OpenRC-less minimal init) ──────────────────────
    cat > "${ROOTFS}/sbin/init" << 'INIT_EOF'
#!/bin/bash
# Jenteck OS minimal init

mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mount -t tmpfs tmpfs /run 2>/dev/null
mount -t tmpfs tmpfs /tmp 2>/dev/null

# Kernel messages to console
echo 3 > /proc/sys/kernel/printk 2>/dev/null

# udev
/usr/sbin/udevd --daemon 2>/dev/null
/usr/sbin/udevadm trigger 2>/dev/null
/usr/sbin/udevadm settle  2>/dev/null

# Hostname
hostname "$(cat /etc/hostname 2>/dev/null || echo jenteck)"

# Network (basic DHCP on eth0/enp*)
for iface in eth0 ens3 enp0s3 enp2s0; do
    ip link set "$iface" up 2>/dev/null && \
    udhcpc -i "$iface" -n -q 2>/dev/null && break
done

# Console login (live: autologin as root)
exec /bin/bash --login < /dev/console >/dev/console 2>/dev/console
INIT_EOF
    chmod +x "${ROOTFS}/sbin/init"

    # ── fstab (minimal) ──────────────────────────────────────────────────
    cat > "${ROOTFS}/etc/fstab" << 'EOF'
# Jenteck OS fstab
tmpfs   /tmp     tmpfs   defaults,nosuid,nodev   0 0
tmpfs   /run     tmpfs   defaults,nosuid,nodev   0 0
proc    /proc    proc    defaults                 0 0
sysfs   /sys     sysfs   defaults                 0 0
devpts  /dev/pts devpts  defaults                 0 0
EOF

    # ── Copy entire rootfs-overlay ────────────────────────────────────────
    cp -rT "${SCRIPT_DIR}/rootfs-overlay" "${ROOTFS}"

    info "✔ Jenteck OS branding & config installed."
}

install_jenteck_installer() {
    banner "Phase 12 — Graphical Installer"

    install -Dm755 "${SCRIPT_DIR}/rootfs-overlay/usr/bin/jenteck-install" \
                   "${ROOTFS}/usr/bin/jenteck-install"

    install -Dm644 \
        "${SCRIPT_DIR}/rootfs-overlay/usr/share/applications/jenteck-install.desktop" \
        "${ROOTFS}/usr/share/applications/jenteck-install.desktop"

    install -Dm644 \
        "${SCRIPT_DIR}/rootfs-overlay/usr/share/polkit-1/actions/uk.co.jenteck.install.policy" \
        "${ROOTFS}/usr/share/polkit-1/actions/uk.co.jenteck.install.policy"

    # Live desktop shortcuts
    local DESK_LIVE="${ROOTFS}/home/jenteck/Desktop"
    local DESK_ROOT="${ROOTFS}/root/Desktop"
    mkdir -p "${DESK_LIVE}" "${DESK_ROOT}"
    cp "${ROOTFS}/usr/share/applications/jenteck-install.desktop" \
       "${DESK_LIVE}/Install Jenteck OS.desktop"
    cp "${ROOTFS}/usr/share/applications/jenteck-install.desktop" \
       "${DESK_ROOT}/Install Jenteck OS.desktop"

    for tool in unsquashfs grub-install grub-mkconfig parted mkfs.ext4 mkfs.fat; do
        { [[ -f "${ROOTFS}/usr/bin/${tool}" ]] || \
          [[ -f "${ROOTFS}/usr/sbin/${tool}" ]] || \
          [[ -f "${ROOTFS}/sbin/${tool}" ]]; } \
            || warn "⚠  ${tool} not found in rootfs — installer may need it at runtime"
    done

    info "✔ Graphical installer → /usr/bin/jenteck-install"
}
