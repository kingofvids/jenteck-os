# Jenteck OS

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

Jenteck OS is a minimal, from-scratch Linux distribution built entirely from upstream source tarballs — **no Debian, no Arch, no Ubuntu base**. It uses:

- **Flatpak** (via Flathub) as the only package manager
- **jenfetch** — a custom branded system info tool (like neofetch)
- **GRUB 2** supporting both UEFI and Legacy BIOS
- **Linux 6.9** kernel with broad hardware support
- **BusyBox + Bash** userland, eudev, util-linux
- Boots on **x86_64** (UEFI + BIOS) and **i686** (BIOS)

---

## Building on a Debian laptop (at your friend's house)

### 1. Install host dependencies

```bash
sudo apt update
sudo apt install -y \
    build-essential bison flex texinfo gawk \
    libelf-dev libssl-dev bc cpio python3 git \
    wget curl xorriso mtools genisoimage \
    grub-pc-bin grub-efi-amd64-bin \
    squashfs-tools dosfstools parted \
    python3-pip
pip3 install meson ninja
```

### 2. Clone / copy the Jenteck OS build tree

```bash
git clone https://github.com/kingofvids/jenteck-os
cd jenteck-os
chmod +x build.sh
```

### 3. Build the 64-bit ISO (recommended — ~2–4 hours)

```bash
./build.sh x86_64
# ISO appears at: output/jenteck-os-x86_64.iso
```

### 4. Build the 32-bit ISO (for older PCs — ~3–5 hours)

```bash
./build.sh i686
# ISO appears at: output/jenteck-os-i686.iso
```

### 5. Resume an interrupted build from a phase

```bash
START_PHASE=5 ./build.sh x86_64   # restart from Flatpak phase
```

### Available phases

| # | Name         | What it does                                  |
|---|--------------|-----------------------------------------------|
| 1 | Toolchain    | Builds GCC cross-compiler + Glibc             |
| 2 | Base System  | BusyBox, Bash, util-linux, e2fsprogs, eudev   |
| 3 | Kernel       | Compiles Linux 6.9 with hardware drivers      |
| 4 | Bootloader   | GRUB (UEFI + BIOS) with Jenteck menu          |
| 5 | Flatpak      | Full Flatpak stack from source + Flathub      |
| 6 | jenfetch     | Installs the custom system info tool          |
| 7 | Config       | Branding, motd, init, hosts, profile          |
| 8 | Initramfs    | Tiny initramfs with squashfs + overlayfs boot |
| 9 | ISO          | Assembles final hybrid UEFI/BIOS ISO          |

---

## Flash to USB

```bash
# Replace /dev/sdX with your USB drive
sudo dd if=output/jenteck-os-x86_64.iso of=/dev/sdX bs=4M status=progress
sync
```

The ISO is **isohybrid** — it boots from both USB and optical disc.

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

## First boot

After booting you'll be logged in as `root`. The system auto-runs **jenfetch**:

```
  ░░░░░░░░░░░░░░░░░░░░░     root@jenteck
  ░██░█████░█░██░██████░    ─────────────
  ░██░██░░░██░██░░██░░░     OS: Jenteck OS 1.0 (x86_64)
  ░██░████░░████░░██░░░     Kernel: 6.9.3
  ░██░██░░░██░██░░██░░░     Uptime: 0m 12s
  ░██████░██░██░██████░     Shell: bash
  ░░░░░░░░░░░░░░░░░░░░░     CPU: Intel Core i5-... (4 cores)
     ░░░░░░░░░░░░░░░         RAM: 124 MiB / 2048 MiB
  ░░  J E N T E C K  ░░    Packages: 0 (flatpak)
```

### Install apps via Flatpak

```bash
# Add Flathub (pre-configured, but run this on first boot)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install apps
flatpak install flathub org.mozilla.firefox
flatpak install flathub com.spotify.Client
flatpak install flathub org.videolan.VLC

# Run
flatpak run org.mozilla.firefox
```

---

## Project structure

```
jenteck-os/
├── build.sh                    ← Main entry point
├── scripts/
│   ├── versions.sh             ← All package versions in one place
│   ├── functions.sh            ← Shared helpers (banner, fetch, etc.)
│   ├── 01-toolchain.sh         ← Cross-compiler (GCC + Glibc)
│   ├── 02-base-system.sh       ← BusyBox, Bash, util-linux, eudev
│   ├── 03-kernel.sh            ← Linux kernel
│   ├── 04-bootloader.sh        ← GRUB (UEFI + BIOS)
│   ├── 05-flatpak.sh           ← Full Flatpak stack from source
│   ├── 06-jenfetch-config.sh   ← jenfetch + branding
│   └── 08-initramfs-iso.sh     ← Initramfs + ISO assembly
├── config/
│   ├── meson-cross-x86_64.txt  ← Meson cross-compile file (64-bit)
│   └── meson-cross-i686.txt    ← Meson cross-compile file (32-bit)
├── rootfs-overlay/
│   └── usr/bin/jenfetch        ← jenfetch source (pure bash)
└── output/
    └── jenteck-os-x86_64.iso   ← Final ISO (generated)
```

---

## jenfetch

`jenfetch` is a pure-bash system info tool. It runs automatically at login.

```bash
jenfetch           # full output with Jenteck logo
jenfetch --no-logo # info only
jenfetch --version
```

---

## Licence

Jenteck OS build scripts: MIT  
All compiled software retains its original licences (GPL, LGPL, etc.)
