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

# ── Download mirrors ─────────────────────────────────────────────────────────
GNU_MIRROR="https://ftp.gnu.org/gnu"
KERNEL_MIRROR="https://cdn.kernel.org/pub/linux/kernel/v6.x"
BUSYBOX_MIRROR="https://busybox.net/downloads"
GRUB_MIRROR="https://ftp.gnu.org/gnu/grub"
GLIB_MIRROR="https://download.gnome.org/sources/glib/2.80"
FLATPAK_MIRROR="https://github.com/flatpak/flatpak/releases/download/${FLATPAK_VER}"
OSTREE_MIRROR="https://github.com/ostreedev/ostree/releases/download/v${OSTREE_VER}"
