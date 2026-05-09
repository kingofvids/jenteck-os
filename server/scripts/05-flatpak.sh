#!/usr/bin/env bash
# =============================================================================
#  Phase 5 — Flatpak Package Manager (built from source)
#  Dependency chain: dbus → glib2 → libxml2 → bubblewrap →
#                    xdg-dbus-proxy → ostree → flatpak
# =============================================================================

install_flatpak() {
    banner "Phase 5 — Building Flatpak Stack"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}-"
    local PKG_CONFIG_PATH="${ROOTFS}/usr/lib/pkgconfig:${ROOTFS}/usr/share/pkgconfig"
    local COMMON_FLAGS="--prefix=/usr --host=${TARGET} --build=${MACHTYPE}
        CC=${CROSS}gcc CXX=${CROSS}g++ PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        PKG_CONFIG_LIBDIR=${ROOTFS}/usr/lib/pkgconfig"

    # ── 5.1 D-Bus ────────────────────────────────────────────────────────────
    info "Building D-Bus ${DBUS_VER} …"
    fetch "https://dbus.freedesktop.org/releases/dbus/dbus-${DBUS_VER}.tar.xz"
    xtract "dbus-${DBUS_VER}.tar.xz"
    pushd "${WORK}/dbus-${DBUS_VER}" >/dev/null
      ./configure ${COMMON_FLAGS} \
        --sysconfdir=/etc --localstatedir=/var \
        --disable-tests --disable-doxygen-docs --disable-xml-docs \
        --disable-static --enable-user-session
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── 5.2 GLib ─────────────────────────────────────────────────────────────
    info "Building GLib ${GLIB_VER} …"
    fetch "${GLIB_MIRROR}/glib-${GLIB_VER}.tar.xz"
    xtract "glib-${GLIB_VER}.tar.xz"
    pushd "${WORK}/glib-${GLIB_VER}" >/dev/null
      # GLib uses Meson — install it on host if missing
      command -v meson >/dev/null 2>&1 || pip3 install meson ninja --quiet
      meson setup builddir \
        --prefix=/usr \
        --cross-file="${SCRIPT_DIR}/config/meson-cross-${ARCH}.txt" \
        --buildtype=release \
        -Dtests=false -Dinstalled_tests=false
      DESTDIR="${ROOTFS}" ninja -C builddir install
    popd >/dev/null

    # ── 5.3 libxml2 ──────────────────────────────────────────────────────────
    info "Building libxml2 ${LIBXML2_VER} …"
    fetch "https://download.gnome.org/sources/libxml2/2.13/libxml2-${LIBXML2_VER}.tar.xz"
    xtract "libxml2-${LIBXML2_VER}.tar.xz"
    pushd "${WORK}/libxml2-${LIBXML2_VER}" >/dev/null
      ./configure ${COMMON_FLAGS} \
        --disable-static --without-python --without-readline
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── 5.4 bubblewrap ───────────────────────────────────────────────────────
    info "Building bubblewrap ${BUBBLEWRAP_VER} …"
    fetch "https://github.com/containers/bubblewrap/releases/download/v${BUBBLEWRAP_VER}/bubblewrap-${BUBBLEWRAP_VER}.tar.xz"
    xtract "bubblewrap-${BUBBLEWRAP_VER}.tar.xz"
    pushd "${WORK}/bubblewrap-${BUBBLEWRAP_VER}" >/dev/null
      meson setup builddir \
        --prefix=/usr \
        --cross-file="${SCRIPT_DIR}/config/meson-cross-${ARCH}.txt" \
        --buildtype=release
      DESTDIR="${ROOTFS}" ninja -C builddir install
    popd >/dev/null

    # ── 5.5 xdg-dbus-proxy ───────────────────────────────────────────────────
    info "Building xdg-dbus-proxy ${XDGDBUSPROXY_VER} …"
    fetch "https://github.com/flatpak/xdg-dbus-proxy/releases/download/${XDGDBUSPROXY_VER}/xdg-dbus-proxy-${XDGDBUSPROXY_VER}.tar.xz"
    xtract "xdg-dbus-proxy-${XDGDBUSPROXY_VER}.tar.xz"
    pushd "${WORK}/xdg-dbus-proxy-${XDGDBUSPROXY_VER}" >/dev/null
      meson setup builddir \
        --prefix=/usr \
        --cross-file="${SCRIPT_DIR}/config/meson-cross-${ARCH}.txt" \
        --buildtype=release
      DESTDIR="${ROOTFS}" ninja -C builddir install
    popd >/dev/null

    # ── 5.6 OSTree ───────────────────────────────────────────────────────────
    info "Building OSTree ${OSTREE_VER} …"
    fetch "${OSTREE_MIRROR}/libostree-${OSTREE_VER}.tar.xz"
    xtract "libostree-${OSTREE_VER}.tar.xz"
    pushd "${WORK}/libostree-${OSTREE_VER}" >/dev/null
      ./configure ${COMMON_FLAGS} \
        --disable-static --disable-man --disable-gtk-doc \
        --with-curl --without-soup --without-avahi \
        --disable-rofiles-fuse
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── 5.7 Flatpak ──────────────────────────────────────────────────────────
    info "Building Flatpak ${FLATPAK_VER} …"
    fetch "${FLATPAK_MIRROR}/flatpak-${FLATPAK_VER}.tar.xz"
    xtract "flatpak-${FLATPAK_VER}.tar.xz"
    pushd "${WORK}/flatpak-${FLATPAK_VER}" >/dev/null
      ./configure ${COMMON_FLAGS} \
        --disable-static --disable-documentation \
        --with-system-bubblewrap="${ROOTFS}/usr/bin/bwrap" \
        --with-system-dbus-proxy="${ROOTFS}/usr/bin/xdg-dbus-proxy" \
        --disable-sandboxed-triggers
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    # ── Flathub remote pre-configured ────────────────────────────────────────
    cat > "${ROOTFS}/etc/flatpak/remotes.d/flathub.flatpakrepo" << 'EOF'
[Flatpak Remote]
Name=flathub
Title=Flathub
Url=https://dl.flathub.org/repo/
Homepage=https://flathub.org
Comment=Central repository of Flatpak applications
Icon=https://dl.flathub.org/repo/logo.svg
GPGKey=mQINBFlD2sABEADsiUZUO...
IsSystem=true
EOF

    info "✔ Flatpak ${FLATPAK_VER} ready. Flathub pre-configured."
}
