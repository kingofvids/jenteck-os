#!/usr/bin/env bash
# =============================================================================
#  Phase 2 — Base System
#  BusyBox (core utilities), Bash, util-linux, e2fsprogs, kmod, eudev
# =============================================================================

build_base_system() {
    banner "Phase 2 — Building Base System"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}"

    # ── 2.1 BusyBox ─────────────────────────────────────────────────────────
    info "Building BusyBox …"
    fetch "${BUSYBOX_MIRROR}/busybox-${BUSYBOX_VER}.tar.bz2"
    xtract "busybox-${BUSYBOX_VER}.tar.bz2"
    pushd "${WORK}/busybox-${BUSYBOX_VER}" >/dev/null
      make ARCH="${ARCH}" CROSS_COMPILE="${CROSS}-" defconfig
      # Enable static build so initramfs works without shared libs
      sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
      sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config  # avoid iproute2 dep
      make ARCH="${ARCH}" CROSS_COMPILE="${CROSS}-" -j"${JOBS}"
      make ARCH="${ARCH}" CROSS_COMPILE="${CROSS}-" \
           CONFIG_PREFIX="${ROOTFS}" install
    popd >/dev/null

    # ── 2.2 Bash ────────────────────────────────────────────────────────────
    info "Building Bash …"
    fetch "${GNU_MIRROR}/bash/bash-${BASH_VER}.tar.gz"
    xtract "bash-${BASH_VER}.tar.gz"
    pushd "${WORK}/bash-${BASH_VER}" >/dev/null
      ./configure --prefix=/usr --host="${TARGET}" \
        --build="${MACHTYPE}" --without-bash-malloc \
        CC="${CROSS}-gcc" CFLAGS="-O2"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
      ln -sf bash "${ROOTFS}/usr/bin/sh"
    popd >/dev/null

    # ── 2.3 util-linux ──────────────────────────────────────────────────────
    info "Building util-linux …"
    fetch "https://github.com/util-linux/util-linux/releases/download/v${UTIL_LINUX_VER}/util-linux-${UTIL_LINUX_VER}.tar.xz"
    xtract "util-linux-${UTIL_LINUX_VER}.tar.xz"
    pushd "${WORK}/util-linux-${UTIL_LINUX_VER}" >/dev/null
      ./configure --prefix=/usr --host="${TARGET}" --build="${MACHTYPE}" \
        --disable-chfn-chsh --disable-login --disable-nologin \
        --disable-su --disable-setpriv --disable-runuser \
        --disable-pylibmount --disable-static \
        --without-python ADJTIME_PATH=/var/lib/hwclock/adjtime \
        CC="${CROSS}-gcc"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── 2.4 e2fsprogs ───────────────────────────────────────────────────────
    info "Building e2fsprogs …"
    fetch "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v${E2FSPROGS_VER}/e2fsprogs-${E2FSPROGS_VER}.tar.gz"
    xtract "e2fsprogs-${E2FSPROGS_VER}.tar.gz"
    pushd "${WORK}/e2fsprogs-${E2FSPROGS_VER}" >/dev/null
      ./configure --prefix=/usr --host="${TARGET}" --build="${MACHTYPE}" \
        --sysconfdir=/etc --enable-elf-shlibs \
        --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck \
        CC="${CROSS}-gcc"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── 2.5 kmod ────────────────────────────────────────────────────────────
    info "Building kmod …"
    fetch "https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kmod/kmod-${KMOD_VER}.tar.xz"
    xtract "kmod-${KMOD_VER}.tar.xz"
    pushd "${WORK}/kmod-${KMOD_VER}" >/dev/null
      ./configure --prefix=/usr --host="${TARGET}" --build="${MACHTYPE}" \
        CC="${CROSS}-gcc"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
      for tool in depmod insmod modinfo modprobe rmmod lsmod; do
          ln -sfv ../bin/kmod "${ROOTFS}/usr/sbin/${tool}"
      done
    popd >/dev/null

    # ── 2.6 eudev (udev without systemd) ────────────────────────────────────
    info "Building eudev …"
    fetch "https://github.com/eudev-project/eudev/releases/download/v${EUDEV_VER}/eudev-${EUDEV_VER}.tar.gz"
    xtract "eudev-${EUDEV_VER}.tar.gz"
    pushd "${WORK}/eudev-${EUDEV_VER}" >/dev/null
      ./configure --prefix=/usr --host="${TARGET}" --build="${MACHTYPE}" \
        --bindir=/usr/sbin --sbindir=/usr/sbin --sysconfdir=/etc \
        --disable-manpages CC="${CROSS}-gcc"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── Essential symlinks & dirs ────────────────────────────────────────────
    ln -sf usr/bin  "${ROOTFS}/bin"
    ln -sf usr/sbin "${ROOTFS}/sbin"
    ln -sf usr/lib  "${ROOTFS}/lib"
    [[ "$ARCH" == "x86_64" ]] && ln -sf usr/lib "${ROOTFS}/lib64"
    chmod 1777 "${ROOTFS}/tmp"

    info "✔ Base system complete."
}
