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
[Flatpak Repo]
Name=flathub
Title=Flathub
Url=https://dl.flathub.org/repo/
Homepage=https://flathub.org
Comment=Central repository of Flatpak applications
Icon=https://dl.flathub.org/repo/logo.svg
GPGKey=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
IsSystem=true
EOF

    info "✔ Flatpak ${FLATPAK_VER} ready. Flathub pre-configured."
}
