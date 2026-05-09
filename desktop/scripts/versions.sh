#!/usr/bin/env bash
# =============================================================================
#  Jenteck OS — Package Versions
#  Edit here to upgrade any component.
# =============================================================================

# ── Toolchain ────────────────────────────────────────────────────────────────
BINUTILS_VER="2.42"
GCC_VER="14.1.0"
GLIBC_VER="2.39"
MPFR_VER="4.2.1"
GMP_VER="6.3.0"
MPC_VER="1.3.1"

# ── Kernel ───────────────────────────────────────────────────────────────────
LINUX_VER="6.9.3"

# ── Core userland ────────────────────────────────────────────────────────────
BUSYBOX_VER="1.36.1"
BASH_VER="5.2.21"
UTIL_LINUX_VER="2.40.1"
E2FSPROGS_VER="1.47.1"
KMOD_VER="32"
UDEV_VER="256"        # systemd-udev standalone via eudev
EUDEV_VER="3.2.14"

# ── Bootloader ───────────────────────────────────────────────────────────────
GRUB_VER="2.12"

# ── Flatpak stack ────────────────────────────────────────────────────────────
# Built from source so we don't need a parent distro
GLIB_VER="2.80.3"
LIBXML2_VER="2.13.1"
OSTREE_VER="2024.6"
BUBBLEWRAP_VER="0.9.0"
XDGDBUSPROXY_VER="0.1.5"
DBUS_VER="1.15.8"
FLATPAK_VER="1.15.8"

# ── X11 / display stack ──────────────────────────────────────────────────────
XORGPROTO_VER="2024.1"
LIBXCB_VER="1.17.0"
LIBX11_VER="1.8.9"
LIBXEXT_VER="1.3.6"
LIBXRENDER_VER="0.9.11"
LIBXRANDR_VER="1.5.4"
LIBXFIXES_VER="6.0.1"
LIBXCOMPOSITE_VER="0.4.6"
LIBXDAMAGE_VER="1.1.6"
LIBXI_VER="1.8.1"
LIBXKBCOMMON_VER="1.7.0"
LIBXKBFILE_VER="1.1.3"
PIXMAN_VER="0.43.4"
FREETYPE_VER="2.13.2"
FONTCONFIG_VER="2.15.0"
CAIRO_VER="1.18.0"
PANGO_VER="1.54.0"
ATK_VER="2.38.0"
GDK_PIXBUF_VER="2.42.12"
HARFBUZZ_VER="9.0.0"
GTK3_VER="3.24.43"
XSERVER_VER="21.1.13"
XORG_MACROS_VER="1.20.1"
XCBUTIL_VER="0.4.1"
XCBUTIL_WM_VER="0.4.2"
XCBUTIL_KEYSYMS_VER="0.4.1"
XCBUTIL_IMAGE_VER="0.4.0"
XCBUTIL_RENDERUTIL_VER="0.3.10"
LIBPCIACCESS_VER="0.18.1"
LIBDRM_VER="2.4.122"
MESA_VER="24.1.2"
XKEYBOARD_CONFIG_VER="2.42"
OPENSSL_VER="3.3.1"
EXPAT_VER="2.6.2"
ZLIB_VER="1.3.1"
LIBPNG_VER="1.6.43"
LIBJPEG_VER="9f"
LIBTIFF_VER="4.6.0"
FRIBIDI_VER="1.0.15"
LIBFFI_VER="3.4.6"
PCRE2_VER="10.43"

# ── XFCE4 components ─────────────────────────────────────────────────────────
XFCE_MIRROR="https://archive.xfce.org/src"
LIBXFCE4UTIL_VER="4.19.3"
XFCONF_VER="4.19.3"
LIBXFCE4UI_VER="4.19.5"
GARCON_VER="4.19.1"
EXO_VER="4.19.1"
XFCE4_PANEL_VER="4.19.5"
XFCE4_SETTINGS_VER="4.19.4"
XFCE4_SESSION_VER="4.19.3"
XFWM4_VER="4.19.1"
XFDESKTOP_VER="4.19.4"
XFCE4_APPFINDER_VER="4.19.1"
THUNAR_VER="4.19.3"
XFCE4_TERMINAL_VER="1.1.3"
XFCE4_NOTIFYD_VER="0.9.5"
XFCE4_POWER_MANAGER_VER="4.19.3"
XFCE4_SCREENSAVER_VER="4.18.3"
MOUSEPAD_VER="0.6.2"     # text editor
RISTRETTO_VER="0.13.2"   # image viewer
XFCE4_TASKMANAGER_VER="1.5.7"
LIGHTDM_VER="1.32.0"
LIGHTDM_GTK_GREETER_VER="2.0.8"

# ── Download mirrors ─────────────────────────────────────────────────────────
GNU_MIRROR="https://ftp.gnu.org/gnu"
KERNEL_MIRROR="https://cdn.kernel.org/pub/linux/kernel/v6.x"
BUSYBOX_MIRROR="https://busybox.net/downloads"
GRUB_MIRROR="https://ftp.gnu.org/gnu/grub"
GLIB_MIRROR="https://download.gnome.org/sources/glib/2.80"
FLATPAK_MIRROR="https://github.com/flatpak/flatpak/releases/download/${FLATPAK_VER}"
OSTREE_MIRROR="https://github.com/ostreedev/ostree/releases/download/v${OSTREE_VER}"
FREEDESKTOP_MIRROR="https://www.freedesktop.org/software"
XORG_MIRROR="https://www.x.org/releases/individual"
GNOME_MIRROR="https://download.gnome.org/sources"
