#!/usr/bin/env bash
# =============================================================================
#  Phase 7b — XFCE4 Desktop Environment
#  Builds all XFCE4 components + LightDM display manager.
#  Component order (strict — each depends on previous):
#    libxfce4util → xfconf → libxfce4ui → garcon → exo
#    → xfce4-panel → xfce4-settings → xfce4-session → xfwm4
#    → xfdesktop → xfce4-appfinder → thunar
#    → xfce4-terminal → xfce4-notifyd → xfce4-power-manager
#    → mousepad → ristretto → xfce4-taskmanager
#    → LightDM → GTK greeter → Jenteck theme
# =============================================================================

build_xfce4() {
    banner "Phase 7b — Building XFCE4 Desktop Environment"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}-"
    local SYSROOT="${ROOTFS}"
    local PKG_CONFIG_PATH="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig"
    local COMMON="--prefix=/usr --host=${TARGET} --build=${MACHTYPE}
        --disable-static
        CC=${CROSS}gcc CXX=${CROSS}g++ PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        CFLAGS=-O2"

    xbuild() {
        local srcdir="$1"; shift
        pushd "${WORK}/${srcdir}" >/dev/null
        ./configure ${COMMON} "$@"
        make -j"${JOBS}"
        make DESTDIR="${SYSROOT}" install
        popd >/dev/null
    }

    mbuild() {
        local srcdir="$1"; shift
        pushd "${WORK}/${srcdir}" >/dev/null
        meson setup builddir \
            --prefix=/usr \
            --cross-file="${SCRIPT_DIR}/config/meson-cross-${ARCH}.txt" \
            --buildtype=release "$@"
        DESTDIR="${SYSROOT}" ninja -C builddir install
        popd >/dev/null
    }

    xfce_fetch() {   # xfce_fetch <component> <version> [subdir]
        local comp="$1" ver="$2" subdir="${3:-$1}"
        local major_ver="${ver%.*}"       # e.g. 4.19 from 4.19.3
        local url="${XFCE_MIRROR}/${subdir}/${major_ver}/${comp}-${ver}.tar.bz2"
        fetch "$url"
        xtract "${comp}-${ver}.tar.bz2"
    }

    # ── 1. libxfce4util ──────────────────────────────────────────────────────
    info "libxfce4util ${LIBXFCE4UTIL_VER}"
    xfce_fetch libxfce4util "${LIBXFCE4UTIL_VER}"
    xbuild "libxfce4util-${LIBXFCE4UTIL_VER}" \
        --disable-introspection --disable-gtk-doc

    # ── 2. xfconf ────────────────────────────────────────────────────────────
    info "xfconf ${XFCONF_VER}"
    xfce_fetch xfconf "${XFCONF_VER}"
    xbuild "xfconf-${XFCONF_VER}" \
        --disable-introspection --disable-gtk-doc

    # ── 3. libxfce4ui ────────────────────────────────────────────────────────
    info "libxfce4ui ${LIBXFCE4UI_VER}"
    xfce_fetch libxfce4ui "${LIBXFCE4UI_VER}"
    xbuild "libxfce4ui-${LIBXFCE4UI_VER}" \
        --disable-introspection --disable-gtk-doc \
        --without-startup-notification

    # ── 4. garcon (menu spec) ────────────────────────────────────────────────
    info "garcon ${GARCON_VER}"
    xfce_fetch garcon "${GARCON_VER}"
    xbuild "garcon-${GARCON_VER}" \
        --disable-introspection --disable-gtk-doc

    # ── 5. exo ───────────────────────────────────────────────────────────────
    info "exo ${EXO_VER}"
    xfce_fetch exo "${EXO_VER}"
    xbuild "exo-${EXO_VER}" \
        --disable-introspection --disable-gtk-doc

    # ── 6. xfce4-panel ───────────────────────────────────────────────────────
    info "xfce4-panel ${XFCE4_PANEL_VER}"
    xfce_fetch xfce4-panel "${XFCE4_PANEL_VER}"
    xbuild "xfce4-panel-${XFCE4_PANEL_VER}" \
        --disable-introspection --disable-gtk-doc \
        --disable-vala

    # ── 7. xfce4-settings ────────────────────────────────────────────────────
    info "xfce4-settings ${XFCE4_SETTINGS_VER}"
    xfce_fetch xfce4-settings "${XFCE4_SETTINGS_VER}"
    xbuild "xfce4-settings-${XFCE4_SETTINGS_VER}" \
        --disable-introspection \
        --enable-xcursor \
        --enable-sound-settings=no \
        --with-x

    # ── 8. xfce4-session ─────────────────────────────────────────────────────
    info "xfce4-session ${XFCE4_SESSION_VER}"
    xfce_fetch xfce4-session "${XFCE4_SESSION_VER}"
    xbuild "xfce4-session-${XFCE4_SESSION_VER}" \
        --disable-gnome-keyring \
        --disable-legacy-sm

    # ── 9. xfwm4 (window manager) ────────────────────────────────────────────
    info "xfwm4 ${XFWM4_VER}"
    xfce_fetch xfwm4 "${XFWM4_VER}"
    xbuild "xfwm4-${XFWM4_VER}" \
        --disable-randr \
        --enable-compositor \
        --enable-startup-notification=no

    # ── 10. xfdesktop ────────────────────────────────────────────────────────
    info "xfdesktop ${XFDESKTOP_VER}"
    xfce_fetch xfdesktop "${XFDESKTOP_VER}"
    xbuild "xfdesktop-${XFDESKTOP_VER}" \
        --disable-introspection \
        --enable-thunarx=no

    # ── 11. xfce4-appfinder ──────────────────────────────────────────────────
    info "xfce4-appfinder ${XFCE4_APPFINDER_VER}"
    xfce_fetch xfce4-appfinder "${XFCE4_APPFINDER_VER}"
    xbuild "xfce4-appfinder-${XFCE4_APPFINDER_VER}"

    # ── 12. Thunar (file manager) ────────────────────────────────────────────
    info "Thunar ${THUNAR_VER}"
    xfce_fetch Thunar "${THUNAR_VER}"
    xbuild "Thunar-${THUNAR_VER}" \
        --disable-introspection \
        --disable-gtk-doc \
        --disable-exif \
        --enable-apr-plugin=no

    # ── 13. xfce4-terminal ───────────────────────────────────────────────────
    info "xfce4-terminal ${XFCE4_TERMINAL_VER}"
    fetch "${XFCE_MIRROR}/apps/xfce4-terminal/1.1/xfce4-terminal-${XFCE4_TERMINAL_VER}.tar.bz2"
    xtract "xfce4-terminal-${XFCE4_TERMINAL_VER}.tar.bz2"
    # xfce4-terminal needs vte3
    info "  (building VTE first)"
    fetch "${GNOME_MIRROR}/vte/0.76/vte-0.76.3.tar.xz"
    xtract "vte-0.76.3.tar.xz"
    mbuild "vte-0.76.3" \
        -Dgir=false -Ddocs=false -Dvapi=false \
        -D_systemd=false -Dgtk3=true -Dgtk4=false
    xbuild "xfce4-terminal-${XFCE4_TERMINAL_VER}"

    # ── 14. xfce4-notifyd ────────────────────────────────────────────────────
    info "xfce4-notifyd ${XFCE4_NOTIFYD_VER}"
    fetch "${XFCE_MIRROR}/apps/xfce4-notifyd/0.9/xfce4-notifyd-${XFCE4_NOTIFYD_VER}.tar.bz2"
    xtract "xfce4-notifyd-${XFCE4_NOTIFYD_VER}.tar.bz2"
    xbuild "xfce4-notifyd-${XFCE4_NOTIFYD_VER}"

    # ── 15. xfce4-power-manager ──────────────────────────────────────────────
    info "xfce4-power-manager ${XFCE4_POWER_MANAGER_VER}"
    xfce_fetch xfce4-power-manager "${XFCE4_POWER_MANAGER_VER}"
    xbuild "xfce4-power-manager-${XFCE4_POWER_MANAGER_VER}" \
        --disable-introspection

    # ── 16. mousepad (text editor) ───────────────────────────────────────────
    info "mousepad ${MOUSEPAD_VER}"
    fetch "${XFCE_MIRROR}/apps/mousepad/0.6/mousepad-${MOUSEPAD_VER}.tar.bz2"
    xtract "mousepad-${MOUSEPAD_VER}.tar.bz2"
    xbuild "mousepad-${MOUSEPAD_VER}"

    # ── 17. ristretto (image viewer) ─────────────────────────────────────────
    info "ristretto ${RISTRETTO_VER}"
    fetch "${XFCE_MIRROR}/apps/ristretto/0.13/ristretto-${RISTRETTO_VER}.tar.bz2"
    xtract "ristretto-${RISTRETTO_VER}.tar.bz2"
    xbuild "ristretto-${RISTRETTO_VER}"

    # ── 18. xfce4-taskmanager ────────────────────────────────────────────────
    info "xfce4-taskmanager ${XFCE4_TASKMANAGER_VER}"
    fetch "${XFCE_MIRROR}/apps/xfce4-taskmanager/1.5/xfce4-taskmanager-${XFCE4_TASKMANAGER_VER}.tar.bz2"
    xtract "xfce4-taskmanager-${XFCE4_TASKMANAGER_VER}.tar.bz2"
    xbuild "xfce4-taskmanager-${XFCE4_TASKMANAGER_VER}"

    info "✔ XFCE4 components installed."
}

# =============================================================================
#  LightDM display manager
# =============================================================================

build_lightdm() {
    banner "Phase 7c — LightDM Display Manager"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${BUILD_DIR}/toolchain/bin:${PATH}"
    local CROSS="${BUILD_DIR}/toolchain/bin/${TARGET}-"
    local SYSROOT="${ROOTFS}"
    local PKG_CONFIG_PATH="${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig"
    local COMMON="--prefix=/usr --host=${TARGET} --build=${MACHTYPE}
        --disable-static
        CC=${CROSS}gcc CXX=${CROSS}g++ PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"

    # ── LightDM ──────────────────────────────────────────────────────────────
    info "LightDM ${LIGHTDM_VER}"
    fetch "https://github.com/canonical/lightdm/releases/download/${LIGHTDM_VER}/lightdm-${LIGHTDM_VER}.tar.xz"
    xtract "lightdm-${LIGHTDM_VER}.tar.xz"
    pushd "${WORK}/lightdm-${LIGHTDM_VER}" >/dev/null
    ./configure ${COMMON} \
        --disable-introspection \
        --disable-tests \
        --disable-gtk-doc \
        --disable-liblightdm-qt \
        --disable-liblightdm-qt5 \
        --with-greeter-user=lightdm \
        --with-greeter-session=lightdm-gtk-greeter \
        CC="${CROSS}gcc" CXX="${CROSS}g++"
    make -j"${JOBS}"
    make DESTDIR="${SYSROOT}" install
    popd >/dev/null

    # ── LightDM GTK greeter ──────────────────────────────────────────────────
    info "lightdm-gtk-greeter ${LIGHTDM_GTK_GREETER_VER}"
    fetch "https://github.com/xubuntu/lightdm-gtk-greeter/releases/download/${LIGHTDM_GTK_GREETER_VER}/lightdm-gtk-greeter-${LIGHTDM_GTK_GREETER_VER}.tar.gz"
    xtract "lightdm-gtk-greeter-${LIGHTDM_GTK_GREETER_VER}.tar.gz"
    pushd "${WORK}/lightdm-gtk-greeter-${LIGHTDM_GTK_GREETER_VER}" >/dev/null
    ./configure ${COMMON} \
        --disable-maintainer-mode \
        CC="${CROSS}gcc"
    make -j"${JOBS}"
    make DESTDIR="${SYSROOT}" install
    popd >/dev/null

    # ── LightDM config ───────────────────────────────────────────────────────
    mkdir -p "${SYSROOT}/etc/lightdm"
    cat > "${SYSROOT}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
run-directory=/run/lightdm
logdir=/var/log/lightdm
log-level=warning

[Seat:*]
greeter-session=lightdm-gtk-greeter
session-wrapper=/etc/lightdm/Xsession
user-session=xfce
autologin-guest=false
EOF

    # Branded greeter config
    cat > "${SYSROOT}/etc/lightdm/lightdm-gtk-greeter.conf" << 'EOF'
[greeter]
background=#0a0f1a
theme-name=Jenteck-Dark
icon-theme-name=hicolor
font-name=DejaVu Sans 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~power
clock-format=%A, %d %B  %H:%M
position=50%,center 50%,center
EOF

    # Xsession wrapper
    cat > "${SYSROOT}/etc/lightdm/Xsession" << 'XSESS'
#!/bin/sh
exec /usr/bin/xfce4-session
XSESS
    chmod +x "${SYSROOT}/etc/lightdm/Xsession"

    # lightdm user
    echo "lightdm:x:998:998:LightDM Display Manager:/var/lib/lightdm:/sbin/nologin" \
        >> "${SYSROOT}/etc/passwd"
    echo "lightdm:x:998:" >> "${SYSROOT}/etc/group"
    mkdir -p "${SYSROOT}/var/lib/lightdm"
    mkdir -p "${SYSROOT}/var/log/lightdm"
    mkdir -p "${SYSROOT}/run/lightdm"

    info "✔ LightDM installed."
}

# =============================================================================
#  Jenteck XFCE4 theme, branding & default config
# =============================================================================

configure_xfce4() {
    banner "Phase 7d — XFCE4 Jenteck Theme & Default Config"
    local SYSROOT="${ROOTFS}"

    # ── Jenteck-Dark GTK theme (hand-crafted, Greybird-inspired) ────────────
    local THEME_DIR="${SYSROOT}/usr/share/themes/Jenteck-Dark"
    mkdir -p "${THEME_DIR}/gtk-3.0"
    mkdir -p "${THEME_DIR}/gtk-2.0"

    cat > "${THEME_DIR}/index.theme" << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Jenteck-Dark
Comment=Jenteck OS dark theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Jenteck-Dark
MetacityTheme=Jenteck-Dark
IconTheme=hicolor
EOF

    # GTK3 CSS
    cat > "${THEME_DIR}/gtk-3.0/gtk.css" << 'EOF'
/* Jenteck-Dark GTK3 Theme */
@define-color bg_color            #1a1f2e;
@define-color fg_color            #e0e8f0;
@define-color base_color          #131820;
@define-color text_color          #d8e4f0;
@define-color selected_bg_color   #00bcd4;
@define-color selected_fg_color   #ffffff;
@define-color tooltip_bg_color    #0d1117;
@define-color tooltip_fg_color    #c9d1d9;
@define-color accent              #00e5ff;
@define-color border              #2a3040;

* { -gtk-icon-style: regular; }

window, .background {
    background-color: @bg_color;
    color: @fg_color;
}

headerbar, .titlebar {
    background-color: #0e1420;
    border-bottom: 1px solid @border;
    color: @fg_color;
    padding: 4px 8px;
}

button {
    background-color: #252d3d;
    border: 1px solid @border;
    border-radius: 4px;
    color: @fg_color;
    padding: 4px 12px;
    transition: all 120ms ease;
}
button:hover {
    background-color: #2e3850;
    border-color: @accent;
    color: @accent;
}
button:active { background-color: #1a2030; }

entry {
    background-color: @base_color;
    border: 1px solid @border;
    border-radius: 4px;
    color: @text_color;
    padding: 4px 8px;
}
entry:focus { border-color: @accent; }

treeview, .view {
    background-color: @base_color;
    color: @text_color;
}
treeview:selected, row:selected {
    background-color: @selected_bg_color;
    color: @selected_fg_color;
}

scrollbar { background-color: @base_color; }
scrollbar slider {
    background-color: #3a4555;
    border-radius: 6px;
    min-width: 8px; min-height: 8px;
}
scrollbar slider:hover { background-color: @accent; }

menubar { background-color: #0e1420; color: @fg_color; }
menu {
    background-color: #171d2e;
    border: 1px solid @border;
    color: @fg_color;
    padding: 4px 0;
}
menuitem:hover {
    background-color: @selected_bg_color;
    color: @selected_fg_color;
}

notebook tab {
    background-color: #1a1f2e;
    border: 1px solid @border;
    padding: 4px 12px;
}
notebook tab:checked {
    background-color: @base_color;
    border-bottom-color: @accent;
}

progressbar progress { background-color: @accent; border-radius: 4px; }
progressbar trough { background-color: @base_color; border-radius: 4px; }

tooltip {
    background-color: @tooltip_bg_color;
    color: @tooltip_fg_color;
    border: 1px solid @border;
    border-radius: 4px;
}

.sidebar, .sidebar row { background-color: #13181f; }
.sidebar row:selected { background-color: @selected_bg_color; }
EOF

    # ── xfwm4 Jenteck-Dark window decorations ────────────────────────────────
    local XFWM_THEME="${SYSROOT}/usr/share/themes/Jenteck-Dark/xfwm4"
    mkdir -p "${XFWM_THEME}"
    cat > "${XFWM_THEME}/themerc" << 'EOF'
# Jenteck-Dark xfwm4 theme
active_color_1=#00bcd4
active_color_2=#0a0f1a
active_hilight_1=#00e5ff
active_hilight_2=#1a1f2e
active_shadow_1=#000000
active_shadow_2=#0d1117
inactive_color_1=#2a3040
inactive_color_2=#1a1f2e
inactive_hilight_1=#3a4555
inactive_hilight_2=#252d3d
inactive_shadow_1=#000000
inactive_shadow_2=#0a0e18
title_font=DejaVu Sans Bold 10
title_horizontal_offset=6
title_vertical_offset_active=3
title_vertical_offset_inactive=3
button_layout=O|HMC
full_width_title=true
borderless_maximize=true
EOF

    # ── XFCE4 default session / panel config (for new users) ─────────────────
    local SKEL="${SYSROOT}/etc/skel"
    mkdir -p "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml"
    mkdir -p "${SKEL}/.config/xfce4/panel"

    # xfce4-session
    cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="LockCommand" type="string" value="xfce4-screensaver-command --lock"/>
    <property name="SessionName" type="string" value="Default"/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client2_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
      <property name="Client3_Command" type="array">
        <value type="string" value="xfce4-terminal"/>
      </property>
      <property name="Client4_Command" type="array">
        <value type="string" value="Thunar"/>
        <value type="string" value="--daemon"/>
      </property>
    </property>
  </property>
</channel>
EOF

    # xsettings (GTK theme)
    cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Jenteck-Dark"/>
    <property name="IconThemeName" type="string" value="hicolor"/>
    <property name="EnableEventSounds" type="bool" value="false"/>
    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="DejaVu Sans 11"/>
    <property name="MonospaceFontName" type="string" value="DejaVu Sans Mono 11"/>
    <property name="CursorThemeName" type="string" value="default"/>
    <property name="ButtonImages" type="bool" value="true"/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="ColorScheme" type="string" value=""/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintfull"/>
    <property name="RGBA" type="string" value="rgb"/>
    <property name="DPI" type="int" value="96"/>
  </property>
</channel>
EOF

    # xfwm4 defaults
    cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Jenteck-Dark"/>
    <property name="title_font" type="string" value="DejaVu Sans Bold 10"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="90"/>
    <property name="inactive_opacity" type="int" value="85"/>
    <property name="show_popup_shadow" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="snap_width" type="int" value="10"/>
    <property name="tile_on_move" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="2"/>
    <property name="workspaces_wrap_around" type="bool" value="true"/>
  </property>
</channel>
EOF

    # xfce4-panel (bottom panel, Jenteck-styled)
    cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=6;x=0;y=0"/>
    <property name="length" type="uint" value="100"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="size" type="uint" value="32"/>
    <property name="background-style" type="uint" value="1"/>
    <property name="background-color" type="string" value="#0e1420ff"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
      <value type="int" value="6"/>
      <value type="int" value="7"/>
      <value type="int" value="8"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="notification-plugin"/>
    <property name="plugin-7" type="string" value="power-manager-plugin"/>
    <property name="plugin-8" type="string" value="clock">
      <property name="digital-format" type="string" value="%a %d %b  %H:%M"/>
    </property>
  </property>
</channel>
EOF

    # xfdesktop (wallpaper + desktop icons)
    cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="2"/>
    <property name="icon-size" type="uint" value="48"/>
    <property name="label-size" type="uint" value="12"/>
    <property name="show-thumbnails" type="bool" value="true"/>
  </property>
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorlvds" type="empty">
        <property name="workspace0" type="empty">
          <property name="color1" type="string" value="#0a0f1a"/>
          <property name="color2" type="string" value="#0d1520"/>
          <property name="color-style" type="int" value="1"/>
          <property name="image-style" type="int" value="0"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

    # xfce4-terminal colours
    mkdir -p "${SKEL}/.config/xfce4/terminal"
    cat > "${SKEL}/.config/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=DejaVu Sans Mono 11
MiscBoldIsBright=TRUE
BackgroundMode=TERMINAL_BACKGROUND_SOLID
ColorForeground=#e0e8f0
ColorBackground=#0a0f1a
ColorCursor=#00e5ff
ColorPalette=#1a1f2e;#ff5555;#50fa7b;#f1fa8c;#6272a4;#ff79c6;#8be9fd;#f8f8f2;#44475a;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ShortcutsNoMnemonics=TRUE
TabActivityColor=#00e5ff
EOF

    # ── .xinitrc / .xsession fallback ────────────────────────────────────────
    cat > "${SKEL}/.xinitrc" << 'EOF'
#!/bin/sh
exec /usr/bin/xfce4-session
EOF
    chmod +x "${SKEL}/.xinitrc"
    cp "${SKEL}/.xinitrc" "${SKEL}/.xsession"

    # ── Live user account ─────────────────────────────────────────────────────
    echo "jenteck:x:1000:1000:Jenteck Live User:/home/jenteck:/bin/bash" \
        >> "${SYSROOT}/etc/passwd"
    echo "jenteck:x:1000:" >> "${SYSROOT}/etc/group"
    echo "jenteck:!:19000:0:99999:7:::" >> "${SYSROOT}/etc/shadow"
    mkdir -p "${SYSROOT}/home/jenteck"
    cp -r "${SKEL}/." "${SYSROOT}/home/jenteck/"
    # Permissions will be set in chroot during first boot
    cat >> "${SYSROOT}/etc/profile" << 'EOF'

# Fix live user home permissions on first boot
if [[ "$(id -u)" == "0" && ! -f /var/lib/.jenteck-setup-done ]]; then
    chown -R jenteck:jenteck /home/jenteck
    touch /var/lib/.jenteck-setup-done
fi
EOF

    # ── LightDM → start at boot via init ─────────────────────────────────────
    # Patch /sbin/init to start LightDM instead of plain shell
    sed -i 's|exec /bin/bash --login.*|# Start X / LightDM\nexec /usr/sbin/lightdm|' \
        "${SYSROOT}/sbin/init"

    # ── Auto-run jenfetch in xfce4-terminal on first open ────────────────────
    cat >> "${SKEL}/.config/xfce4/terminal/terminalrc" << 'EOF'
RunCustomCommand=TRUE
CustomCommand=bash -c "jenfetch; exec bash"
EOF

    info "✔ XFCE4 Jenteck theme and defaults configured."
}
