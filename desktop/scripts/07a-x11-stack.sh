#!/usr/bin/env bash
# =============================================================================
#  Phase 7a — X11 Display Stack
#  Build order (each depends on the previous):
#    zlib → expat → openssl → libffi → pcre2
#    → freetype2 → fontconfig → libpng → libjpeg → harfbuzz
#    → pixman → cairo → fribidi → pango → atk → gdk-pixbuf → gtk3
#    → xorgproto → libxcb → libX11 + extensions
#    → libxkbcommon → libpciaccess → libdrm → Mesa
#    → Xorg server
# =============================================================================

build_x11_stack() {
    banner "Phase 7a — Building X11 Display Stack"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}-"
    local SYSROOT="${ROOTFS}"
    local PKG_CONFIG_PATH="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig"
    local CFLAGS="-O2 -pipe"
    local COMMON="--prefix=/usr --host=${TARGET} --build=${MACHTYPE}
        --disable-static
        CC=${CROSS}gcc CXX=${CROSS}g++ PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"

    xbuild() {   # autoconf wrapper: xbuild <srcdir> [extra configure args...]
        local srcdir="$1"; shift
        pushd "${WORK}/${srcdir}" >/dev/null
        ./configure ${COMMON} "$@"
        make -j"${JOBS}"
        make DESTDIR="${SYSROOT}" install
        popd >/dev/null
    }

    mbuild() {   # meson wrapper
        local srcdir="$1"; shift
        pushd "${WORK}/${srcdir}" >/dev/null
        meson setup builddir \
            --prefix=/usr \
            --cross-file="${SCRIPT_DIR}/config/meson-cross-${ARCH}.txt" \
            --buildtype=release \
            "$@"
        DESTDIR="${SYSROOT}" ninja -C builddir install
        popd >/dev/null
    }

    # ── Primitive libs ───────────────────────────────────────────────────────
    info "zlib ${ZLIB_VER}"
    fetch "https://zlib.net/zlib-${ZLIB_VER}.tar.gz"
    xtract "zlib-${ZLIB_VER}.tar.gz"
    pushd "${WORK}/zlib-${ZLIB_VER}" >/dev/null
    CC="${CROSS}gcc" ./configure --prefix=/usr --shared
    make -j"${JOBS}"; make DESTDIR="${SYSROOT}" install
    popd >/dev/null

    info "expat ${EXPAT_VER}"
    fetch "https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VER//./_}/expat-${EXPAT_VER}.tar.xz"
    xtract "expat-${EXPAT_VER}.tar.xz"
    xbuild "expat-${EXPAT_VER}"

    info "libffi ${LIBFFI_VER}"
    fetch "https://github.com/libffi/libffi/releases/download/v${LIBFFI_VER}/libffi-${LIBFFI_VER}.tar.gz"
    xtract "libffi-${LIBFFI_VER}.tar.gz"
    xbuild "libffi-${LIBFFI_VER}" --disable-docs

    info "PCRE2 ${PCRE2_VER}"
    fetch "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VER}/pcre2-${PCRE2_VER}.tar.bz2"
    xtract "pcre2-${PCRE2_VER}.tar.bz2"
    xbuild "pcre2-${PCRE2_VER}" --enable-pcre2-8 --enable-pcre2-16 --enable-unicode

    info "OpenSSL ${OPENSSL_VER}"
    fetch "https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz"
    xtract "openssl-${OPENSSL_VER}.tar.gz"
    pushd "${WORK}/openssl-${OPENSSL_VER}" >/dev/null
    local SSL_ARCH; [[ "$ARCH" == "x86_64" ]] && SSL_ARCH="linux-x86_64" || SSL_ARCH="linux-elf"
    CC="${CROSS}gcc" ./Configure "${SSL_ARCH}" --prefix=/usr --openssldir=/etc/ssl shared
    make -j"${JOBS}"; make DESTDIR="${SYSROOT}" install_sw
    popd >/dev/null

    # ── Image / font libs ────────────────────────────────────────────────────
    info "libpng ${LIBPNG_VER}"
    fetch "https://downloads.sourceforge.net/libpng/libpng-${LIBPNG_VER}.tar.xz"
    xtract "libpng-${LIBPNG_VER}.tar.xz"
    xbuild "libpng-${LIBPNG_VER}"

    info "libjpeg-turbo"
    fetch "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.0.3/libjpeg-turbo-3.0.3.tar.gz"
    xtract "libjpeg-turbo-3.0.3.tar.gz"
    pushd "${WORK}/libjpeg-turbo-3.0.3" >/dev/null
    cmake -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_C_COMPILER="${CROSS}gcc" \
          -DCMAKE_INSTALL_LIBDIR=/usr/lib \
          -DWITH_JPEG8=1 -B build
    cmake --build build -j"${JOBS}"
    DESTDIR="${SYSROOT}" cmake --install build
    popd >/dev/null

    info "FreeType ${FREETYPE_VER}"
    fetch "https://downloads.sourceforge.net/freetype/freetype-${FREETYPE_VER}.tar.xz"
    xtract "freetype-${FREETYPE_VER}.tar.xz"
    xbuild "freetype-${FREETYPE_VER}" --enable-freetype-config \
        --with-bzip2=no --with-harfbuzz=no  # bootstrap (no harfbuzz yet)

    info "Fontconfig ${FONTCONFIG_VER}"
    fetch "${FREEDESKTOP_MIRROR}/fontconfig/release/fontconfig-${FONTCONFIG_VER}.tar.xz"
    xtract "fontconfig-${FONTCONFIG_VER}.tar.xz"
    xbuild "fontconfig-${FONTCONFIG_VER}" --disable-docs

    info "HarfBuzz ${HARFBUZZ_VER}"
    fetch "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VER}/harfbuzz-${HARFBUZZ_VER}.tar.xz"
    xtract "harfbuzz-${HARFBUZZ_VER}.tar.xz"
    mbuild "harfbuzz-${HARFBUZZ_VER}" \
        -Dtests=disabled -Ddocs=disabled -Dbenchmark=disabled

    # Rebuild FreeType with HarfBuzz now available
    info "FreeType (rebuild with HarfBuzz)"
    pushd "${WORK}/freetype-${FREETYPE_VER}" >/dev/null
    ./configure ${COMMON} --enable-freetype-config --with-harfbuzz=yes
    make -j"${JOBS}"; make DESTDIR="${SYSROOT}" install
    popd >/dev/null

    # ── Cairo / Pango / GTK stack ────────────────────────────────────────────
    info "Pixman ${PIXMAN_VER}"
    fetch "https://www.cairographics.org/releases/pixman-${PIXMAN_VER}.tar.gz"
    xtract "pixman-${PIXMAN_VER}.tar.gz"
    mbuild "pixman-${PIXMAN_VER}" -Dtests=disabled -Ddemos=disabled

    info "Cairo ${CAIRO_VER}"
    fetch "https://www.cairographics.org/releases/cairo-${CAIRO_VER}.tar.xz"
    xtract "cairo-${CAIRO_VER}.tar.xz"
    mbuild "cairo-${CAIRO_VER}" -Dtests=disabled

    info "FriBidi ${FRIBIDI_VER}"
    fetch "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VER}/fribidi-${FRIBIDI_VER}.tar.xz"
    xtract "fribidi-${FRIBIDI_VER}.tar.xz"
    mbuild "fribidi-${FRIBIDI_VER}" -Ddocs=false -Dtests=false

    info "Pango ${PANGO_VER}"
    fetch "${GNOME_MIRROR}/pango/${PANGO_VER%.*}/pango-${PANGO_VER}.tar.xz"
    xtract "pango-${PANGO_VER}.tar.xz"
    mbuild "pango-${PANGO_VER}" -Dintrospection=disabled -Dgtk_doc=false

    info "ATK ${ATK_VER}"
    fetch "${GNOME_MIRROR}/atk/${ATK_VER%.*}/atk-${ATK_VER}.tar.xz"
    xtract "atk-${ATK_VER}.tar.xz"
    mbuild "atk-${ATK_VER}" -Dintrospection=false

    info "gdk-pixbuf ${GDK_PIXBUF_VER}"
    fetch "${GNOME_MIRROR}/gdk-pixbuf/${GDK_PIXBUF_VER%.*}/gdk-pixbuf-${GDK_PIXBUF_VER}.tar.xz"
    xtract "gdk-pixbuf-${GDK_PIXBUF_VER}.tar.xz"
    mbuild "gdk-pixbuf-${GDK_PIXBUF_VER}" \
        -Dintrospection=disabled -Dman=false -Dgtk_doc=false \
        -Dbuiltin_loaders=png,jpeg

    info "GTK+ 3 ${GTK3_VER}"
    fetch "${GNOME_MIRROR}/gtk+/${GTK3_VER%.*}/gtk+-${GTK3_VER}.tar.xz"
    xtract "gtk+-${GTK3_VER}.tar.xz"
    mbuild "gtk+-${GTK3_VER}" \
        -Dintrospection=false -Ddemos=false -Dexamples=false \
        -Dtests=false -Dinstall-tests=false \
        -Dprint_backends=file \
        -Dcolord=no -Dcloudproviders=false

    # ── X11 protocol headers ─────────────────────────────────────────────────
    info "xorgproto ${XORGPROTO_VER}"
    fetch "${XORG_MIRROR}/proto/xorgproto-${XORGPROTO_VER}.tar.xz"
    xtract "xorgproto-${XORGPROTO_VER}.tar.xz"
    mbuild "xorgproto-${XORGPROTO_VER}"

    info "xcb-proto"
    fetch "${XORG_MIRROR}/proto/xcb-proto-1.17.0.tar.xz"
    xtract "xcb-proto-1.17.0.tar.xz"
    xbuild "xcb-proto-1.17.0"

    info "libxcb ${LIBXCB_VER}"
    fetch "${XORG_MIRROR}/lib/libxcb-${LIBXCB_VER}.tar.xz"
    xtract "libxcb-${LIBXCB_VER}.tar.xz"
    xbuild "libxcb-${LIBXCB_VER}" --without-doxygen

    # xcb utilities
    for pkg in \
        "xcb-util-${XCBUTIL_VER}|${XORG_MIRROR}/lib/xcb-util-${XCBUTIL_VER}.tar.xz" \
        "xcb-util-wm-${XCBUTIL_WM_VER}|${XORG_MIRROR}/lib/xcb-util-wm-${XCBUTIL_WM_VER}.tar.xz" \
        "xcb-util-keysyms-${XCBUTIL_KEYSYMS_VER}|${XORG_MIRROR}/lib/xcb-util-keysyms-${XCBUTIL_KEYSYMS_VER}.tar.xz" \
        "xcb-util-image-${XCBUTIL_IMAGE_VER}|${XORG_MIRROR}/lib/xcb-util-image-${XCBUTIL_IMAGE_VER}.tar.xz" \
        "xcb-util-renderutil-${XCBUTIL_RENDERUTIL_VER}|${XORG_MIRROR}/lib/xcb-util-renderutil-${XCBUTIL_RENDERUTIL_VER}.tar.xz"
    do
        local name="${pkg%%|*}" url="${pkg##*|}"
        info "${name}"
        fetch "$url"
        xtract "$(basename "$url")"
        xbuild "${name}"
    done

    # Core X11 libs
    for pkg in \
        "libX11-${LIBX11_VER}|${XORG_MIRROR}/lib/libX11-${LIBX11_VER}.tar.xz" \
        "libXext-${LIBXEXT_VER}|${XORG_MIRROR}/lib/libXext-${LIBXEXT_VER}.tar.xz" \
        "libXrender-${LIBXRENDER_VER}|${XORG_MIRROR}/lib/libXrender-${LIBXRENDER_VER}.tar.xz" \
        "libXrandr-${LIBXRANDR_VER}|${XORG_MIRROR}/lib/libXrandr-${LIBXRANDR_VER}.tar.xz" \
        "libXfixes-${LIBXFIXES_VER}|${XORG_MIRROR}/lib/libXfixes-${LIBXFIXES_VER}.tar.xz" \
        "libXcomposite-${LIBXCOMPOSITE_VER}|${XORG_MIRROR}/lib/libXcomposite-${LIBXCOMPOSITE_VER}.tar.xz" \
        "libXdamage-${LIBXDAMAGE_VER}|${XORG_MIRROR}/lib/libXdamage-${LIBXDAMAGE_VER}.tar.xz" \
        "libXi-${LIBXI_VER}|${XORG_MIRROR}/lib/libXi-${LIBXI_VER}.tar.xz" \
        "libxkbfile-${LIBXKBFILE_VER}|${XORG_MIRROR}/lib/libxkbfile-${LIBXKBFILE_VER}.tar.xz"
    do
        local name="${pkg%%|*}" url="${pkg##*|}"
        info "${name}"
        fetch "$url"
        xtract "$(basename "$url")"
        xbuild "${name}"
    done

    info "libxkbcommon ${LIBXKBCOMMON_VER}"
    fetch "https://xkbcommon.org/download/libxkbcommon-${LIBXKBCOMMON_VER}.tar.xz"
    xtract "libxkbcommon-${LIBXKBCOMMON_VER}.tar.xz"
    mbuild "libxkbcommon-${LIBXKBCOMMON_VER}" \
        -Denable-docs=false -Denable-wayland=false \
        -Denable-xkbregistry=false

    # ── DRM / Mesa ───────────────────────────────────────────────────────────
    info "libpciaccess ${LIBPCIACCESS_VER}"
    fetch "${XORG_MIRROR}/lib/libpciaccess-${LIBPCIACCESS_VER}.tar.xz"
    xtract "libpciaccess-${LIBPCIACCESS_VER}.tar.xz"
    mbuild "libpciaccess-${LIBPCIACCESS_VER}"

    info "libdrm ${LIBDRM_VER}"
    fetch "${FREEDESKTOP_MIRROR}/drm/libdrm-${LIBDRM_VER}.tar.xz"
    xtract "libdrm-${LIBDRM_VER}.tar.xz"
    mbuild "libdrm-${LIBDRM_VER}" \
        -Dintel=enabled -Damdgpu=enabled -Dradeon=enabled \
        -Dnouveau=enabled -Dvmwgfx=enabled \
        -Dtests=false -Dman-pages=disabled

    info "Mesa ${MESA_VER} (software + basic DRI — takes a while)"
    fetch "https://mesa.freedesktop.org/archive/mesa-${MESA_VER}.tar.xz"
    xtract "mesa-${MESA_VER}.tar.xz"
    mbuild "mesa-${MESA_VER}" \
        -Dgallium-drivers=softpipe,svga,r300,r600,radeonsi,nouveau,iris,crocus,i915,swrast \
        -Ddri-drivers=[] \
        -Dvulkan-drivers=[] \
        -Dglx=dri \
        -Dopengl=true \
        -Dgles1=disabled \
        -Dgles2=disabled \
        -Dllvm=disabled \
        -Dshared-llvm=disabled \
        -Dplatforms=x11 \
        -Dbuildtype=release

    # ── Xorg server ──────────────────────────────────────────────────────────
    info "xkeyboard-config ${XKEYBOARD_CONFIG_VER}"
    fetch "${FREEDESKTOP_MIRROR}/xkeyboard-config/xkeyboard-config-${XKEYBOARD_CONFIG_VER}.tar.bz2"
    xtract "xkeyboard-config-${XKEYBOARD_CONFIG_VER}.tar.bz2"
    mbuild "xkeyboard-config-${XKEYBOARD_CONFIG_VER}"

    info "Xorg server ${XSERVER_VER}"
    fetch "${XORG_MIRROR}/xserver/xorg-server-${XSERVER_VER}.tar.xz"
    xtract "xorg-server-${XSERVER_VER}.tar.xz"
    mbuild "xorg-server-${XSERVER_VER}" \
        -Dxorg=true -Dxvfb=true -Dxephyr=false \
        -Dglamor=false \
        -Dxwayland=false \
        -Dipv6=true \
        -Dsuid_wrapper=true \
        -Dxkb_dir=/usr/share/X11/xkb \
        -Dxkb_output_dir=/var/lib/xkb

    # ── Xorg input/video drivers ─────────────────────────────────────────────
    info "xf86-input-libinput"
    fetch "${XORG_MIRROR}/driver/xf86-input-libinput-1.4.0.tar.xz"
    xtract "xf86-input-libinput-1.4.0.tar.xz"
    xbuild "xf86-input-libinput-1.4.0"

    info "xf86-video-fbdev"
    fetch "${XORG_MIRROR}/driver/xf86-video-fbdev-0.5.0.tar.xz"
    xtract "xf86-video-fbdev-0.5.0.tar.xz"
    xbuild "xf86-video-fbdev-0.5.0"

    info "xf86-video-vesa"
    fetch "${XORG_MIRROR}/driver/xf86-video-vesa-2.6.0.tar.xz"
    xtract "xf86-video-vesa-2.6.0.tar.xz"
    xbuild "xf86-video-vesa-2.6.0"

    info "xf86-video-vmware"
    fetch "${XORG_MIRROR}/driver/xf86-video-vmware-13.4.0.tar.bz2"
    xtract "xf86-video-vmware-13.4.0.tar.bz2"
    xbuild "xf86-video-vmware-13.4.0"

    # ── Default Xorg config ──────────────────────────────────────────────────
    mkdir -p "${SYSROOT}/etc/X11/xorg.conf.d"
    cat > "${SYSROOT}/etc/X11/xorg.conf.d/10-keyboard.conf" << 'EOF'
Section "InputClass"
    Identifier "keyboard defaults"
    MatchIsKeyboard "on"
    Option "XkbLayout" "gb"
    Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
EOF

    cat > "${SYSROOT}/etc/X11/xorg.conf.d/20-gpu.conf" << 'EOF'
Section "Device"
    Identifier "Jenteck GPU"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
EndSection

Section "ServerFlags"
    Option "AutoAddDevices" "true"
    Option "AutoEnableDevices" "true"
EndSection
EOF

    # ── Install fonts ────────────────────────────────────────────────────────
    info "Installing DejaVu fonts"
    fetch "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2"
    xtract "dejavu-fonts-ttf-2.37.tar.bz2"
    mkdir -p "${SYSROOT}/usr/share/fonts/dejavu"
    cp "${WORK}/dejavu-fonts-ttf-2.37/ttf/"*.ttf "${SYSROOT}/usr/share/fonts/dejavu/"

    info "Installing Noto Sans (base)"
    fetch "https://github.com/notofonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf"
    mkdir -p "${SYSROOT}/usr/share/fonts/noto"
    cp "${BUILD_DIR}/sources/NotoSans-Regular.ttf" "${SYSROOT}/usr/share/fonts/noto/"

    info "✔ X11 display stack complete."
}
