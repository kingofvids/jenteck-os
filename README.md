#Jenteck OS #Xfce and other Desktop related things are only for the desktop build
> A from-scratch Linux distribution. No parent distro. Pure LFS spirit.

```
     ██╗███████╗███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗
     ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║ ██╔╝
     ██║█████╗  ██╔██╗ ██║   ██║   █████╗  ██║     █████╔╝
██   ██║██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔═██╗
╚█████╔╝███████╗██║ ╚████║   ██║   ███████╗╚██████╗██║  ██╗
 ╚════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝
```

---

## What is Jenteck OS?

Jenteck OS is a minimal, **from-scratch** Linux distribution built entirely
from upstream source tarballs — **no Debian, no Arch, no Ubuntu base**.

| Feature | Detail |
|---|---|
| Desktop | **XFCE4** with Jenteck-Dark theme |
| Package manager | **Flatpak** (Flathub pre-configured) |
| System info | **jenfetch** — custom branded neofetch |
| Bootloader | **GRUB 2** — UEFI *and* Legacy BIOS |
| Kernel | **Linux 6.9** — broad hardware support |
| Userland | BusyBox + Bash + eudev + util-linux |
| Display manager | **LightDM** + GTK greeter |
| Installer | **jenteck-install** — GTK3 graphical wizard |
| Architectures | **x86\_64** (UEFI + BIOS) · **i686** (BIOS) |

---

## Building on a Debian laptop - preferably debian 12

### 1. Install host packages

```bash
sudo apt update
sudo apt install -y \
    build-essential bison flex texinfo gawk git wget curl \
    libelf-dev libssl-dev bc cpio cmake ninja-build \
    xorriso mtools genisoimage squashfs-tools dosfstools parted \
    grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin \
    python3 python3-pip \
    python3-gi python3-gi-cairo gir1.2-gtk-3.0
pip3 install --upgrade meson ninja
```

### 2. Clone / copy the build tree

```bash
git clone https://github.com/kingofvids/jenteck-os
cd jenteck-os
cd desktop / cd server for the server build
chmod +x build.sh
```

### 3. Build the 64-bit ISO (~3–6 hours)

```bash
./build.sh x86_64
# → output/jenteck-os-x86_64.iso
```

### 4. Build the 32-bit ISO (~4–7 hours)

```bash
./build.sh i686
# → output/jenteck-os-i686.iso
```

### 5. Resume an interrupted build

```bash
START_PHASE=8 ./build.sh x86_64    # restart from X11 stack
START_PHASE=9 ./build.sh x86_64    # restart from XFCE4
START_PHASE=13 ./build.sh x86_64   # just rebuild the ISO
```

---

## Build phases

| # | Name | What it builds |
|---|------|----------------|
| 1 | Cross-Toolchain | GCC cross-compiler + Glibc |
| 2 | Base System | BusyBox, Bash, util-linux, e2fsprogs, eudev |
| 3 | Linux Kernel | Linux 6.9 with USB/AHCI/NVMe/WiFi/VirtIO drivers |
| 4 | Bootloader | GRUB UEFI + BIOS with Jenteck branded menu |
| 5 | Flatpak | Full Flatpak stack from source + Flathub config |
| 6 | jenfetch | Custom branded system info tool |
| 7 | Branding | motd, init, os-release, profile, aliases |
| 8 | X11 Stack | Xorg, Mesa, GTK3, Cairo, Pango, fonts |
| 9 | XFCE4 | Full XFCE4 desktop + Thunar + Terminal + apps |
| 10 | LightDM | Display manager + GTK greeter |
| 11 | XFCE4 Theme | Jenteck-Dark theme, panel layout, defaults |
| 12 | Installer | jenteck-install GTK3 graphical installer wizard |
| 13 | Initramfs | Tiny initramfs (squashfs + overlayfs boot) |
| 14 | ISO | xorriso hybrid UEFI/BIOS ISO assembly |

---

## Flash to USB

```bash
sudo dd if=output/jenteck-os-x86_64.iso of=/dev/sdX bs=4M status=progress
sync
```

The ISO is **isohybrid** — boots from USB and optical disc on both UEFI and BIOS.

---

## Test in a VM (QEMU)

```bash
# 64-bit UEFI
qemu-system-x86_64 -m 2G -bios /usr/share/ovmf/OVMF.fd \
    -cdrom output/jenteck-os-x86_64.iso -boot d

# 64-bit Legacy BIOS
qemu-system-x86_64 -m 2G -cdrom output/jenteck-os-x86_64.iso -boot d

# 32-bit Legacy BIOS
qemu-system-i386 -m 1G -cdrom output/jenteck-os-i686.iso -boot d
```

---

## First boot (live session)

The live system boots directly into **XFCE4** via LightDM (auto-login as `jenteck`).

Opening a terminal automatically runs **jenfetch**:

```
  ░░░░░░░░░░░░░░░░░░░░░     jenteck@jenteck
  ░ ░░░░░ ░  ░░░░░ ░░░░     ───────────────
  ░     ░ ░  ░     ░  ░     OS:     Jenteck OS 1.0 (x86_64)
  ░ ░░░░░ ░  ░░░░░ ░  ░     Kernel: 6.9.3
  ░ ░     ░  ░     ░  ░     Shell:  bash
  ░ ░     ░░ ░░░░░ ░░░░     CPU:    Intel Core i5 (4 cores)
  ░░░░░░░░░░░░░░░░░░░░░     RAM:    312 MiB / 2048 MiB
   JENTECK OS · Installer   Disk:   — / — (live)
                             Packages: 0 (flatpak)
```

---

## Graphical Installer

Double-click **"Install Jenteck OS"** on the desktop, or run:

```bash
jenteck-install
```

The installer wizard walks through 7 screens:

1. **Welcome** — overview
2. **Select Disk** — picks target drive, shows size and model
3. **Partition Layout** — auto (EFI + root + swap) or manual shell
4. **Locale & Timezone** — language, region, keyboard
5. **User Account** — username, password, hostname, autologin
6. **Summary** — review before committing
7. **Progress** — live log of partitioning, file copy, GRUB install
8. **Done** — reboot or stay in live session

---

## Install apps via Flatpak (after installation)

```bash
# Add Flathub (pre-configured, but run once on first boot)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install apps
flatpak install flathub org.mozilla.firefox
flatpak install flathub com.spotify.Client
flatpak install flathub org.videolan.VLC
flatpak install flathub org.gimp.GIMP

# Run
flatpak run org.mozilla.firefox
```

---

## Project structure

```
jenteck-os/
├── build.sh                         ← Entry point
├── scripts/
│   ├── versions.sh                  ← All package versions
│   ├── functions.sh                 ← Shared helpers
│   ├── 01-toolchain.sh              ← Cross-compiler (GCC + Glibc)
│   ├── 02-base-system.sh            ← BusyBox, Bash, util-linux, eudev
│   ├── 03-kernel.sh                 ← Linux 6.9
│   ├── 04-bootloader.sh             ← GRUB (UEFI + BIOS)
│   ├── 05-flatpak.sh                ← Flatpak stack from source
│   ├── 06-jenfetch-config.sh        ← jenfetch, branding, installer phase
│   ├── 07a-x11-stack.sh             ← Xorg, Mesa, GTK3, Cairo, Pango
│   ├── 07b-xfce4.sh                 ← XFCE4, LightDM, theme, defaults
│   └── 08-initramfs-iso.sh          ← Initramfs + ISO assembly
├── config/
│   ├── meson-cross-x86_64.txt
│   └── meson-cross-i686.txt
├── rootfs-overlay/
│   └── usr/
│       ├── bin/
│       │   ├── jenfetch             ← jenfetch (pure bash)
│       │   └── jenteck-install      ← GTK3 installer (Python3)
│       └── share/
│           ├── applications/
│           │   └── jenteck-install.desktop
│           └── polkit-1/actions/
│               └── uk.co.jenteck.install.policy
└── output/
    └── jenteck-os-x86_64.iso        ← Final ISO (generated)
```

---

## Licence

Jenteck OS build scripts: MIT
All compiled software retains its original licences (GPL, LGPL, etc.)
