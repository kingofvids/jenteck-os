<div align="center">
     ██╗███████╗███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗
     ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║ ██╔╝
     ██║█████╗  ██╔██╗ ██║   ██║   █████╗  ██║     █████╔╝
██   ██║██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔═██╗
╚█████╔╝███████╗██║ ╚████║   ██║   ███████╗╚██████╗██║  ██╗
 ╚════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝
Jenteck OS
Born from scratch. Built for you.
Show Image
Show Image
Show Image
Show Image
Show Image
Two editions — Desktop and Server — built entirely from source. No parent distro.
Desktop Edition · Server Edition · Building · Installer · Flatpak · jenfetch
</div>

What is Jenteck OS?
Jenteck OS is a Linux distribution compiled entirely from upstream source tarballs using a custom cross-toolchain. There is no Debian, Arch, Ubuntu, or any other distribution underneath — every binary is built from scratch in the spirit of Linux From Scratch.
It comes in two editions built from the same codebase and the same kernel:
DesktopServerPurposeFull daily-driver desktopHeadless / minimal baseDesktop environmentXFCE4 + Jenteck-Dark themeNone — TTY onlyDisplay managerLightDM + branded GTK greeterNoneInstallerGTK3 graphical wizardManual partitioning + chrootPackage managerFlatpak (Flathub pre-configured)Flatpak (Flathub pre-configured)System info tooljenfetch (with logo)jenfetch (with logo)BootloaderGRUB 2 — UEFI + Legacy BIOSGRUB 2 — UEFI + Legacy BIOSKernelLinux 6.9.3Linux 6.9.3Architecturesx86_64 · i686x86_64 · i686Minimum RAM512 MiB128 MiBMinimum disk10 GiB3 GiB

Desktop Edition
The Desktop edition boots into a full XFCE4 environment via LightDM. It is designed to be a complete, usable desktop operating system right out of the box, with a custom dark theme and Flatpak as the route to installing any application.
What's included

XFCE4 — xfwm4 window manager, xfce4-panel, xfdesktop, xfce4-session, xfce4-settings, xfce4-appfinder
Thunar — file manager
xfce4-terminal — terminal emulator, auto-opens with jenfetch
Mousepad — text editor
Ristretto — image viewer
xfce4-taskmanager — task / process manager
xfce4-notifyd — desktop notification daemon
xfce4-power-manager — battery and power management
LightDM — display manager with a Jenteck-branded GTK3 greeter
Flatpak + Flathub — install any app from the Flathub catalogue
jenfetch — custom system info tool, shown on every terminal open
jenteck-install — graphical installer wizard (see Graphical Installer)
Jenteck-Dark theme — custom dark GTK3 + xfwm4 theme with cyan accents

Live session
Booting the Desktop ISO drops you into XFCE4, auto-logged in as the jenteck user. An Install Jenteck OS shortcut sits on the desktop. Everything works from the live session — you can explore, open a terminal, test hardware, and browse the Flathub catalogue before committing to an install.
jenfetch in the terminal
Every time you open xfce4-terminal, jenfetch runs automatically:
  ░░░░░░░░░░░░░░░░░░░░░     jenteck@jenteck
  ░ ░░░░░ ░  ░░░░░ ░░░░     ──────────────────────────────
  ░     ░ ░  ░     ░  ░     OS       Jenteck OS 1.0 Desktop (x86_64)
  ░ ░░░░░ ░  ░░░░░ ░  ░     Kernel   6.9.3-jenteck
  ░ ░     ░  ░     ░  ░     Uptime   4m 12s
  ░ ░     ░░ ░░░░░ ░░░░     Shell    bash 5.2.21
  ░░░░░░░░░░░░░░░░░░░░░     CPU      Intel Core i5-8250U (4 cores)
   J E N T E C K   O S      RAM      389 MiB / 4096 MiB
                             Disk     — / — (live session)
                             Packages 0 (flatpak)

Server Edition
The Server edition is a stripped-down build with no graphical stack at all. It boots to a login prompt on the console and is intended for headless machines, VMs, and anyone who wants a clean, minimal Linux base to build on top of — with no systemd, no bloat, and nothing you didn't ask for.
What's included

BusyBox + Bash — shell and core UNIX utilities
util-linux — mount, lsblk, fdisk, blkid, and friends
eudev — device manager (no systemd dependency)
kmod — kernel module loading (depmod, modprobe, insmod)
e2fsprogs — ext4 filesystem tools
Flatpak — same package manager as the Desktop edition, fully headless-compatible
jenfetch — works in any TTY, clean output even without colour support
GRUB 2 — same UEFI + Legacy BIOS bootloader as Desktop
Minimal init — hand-written /sbin/init, no systemd, no OpenRC, no SysV
Basic networking — DHCP via udhcpc on the first Ethernet interface at boot

First login
Jenteck OS 1.0 Server  tty1

jenteck login: root
Password: jenteck

  ╔══════════════════════════════════════════════╗
  ║   Welcome to  J E N T E C K   O S            ║
  ║   Born from scratch. Built for you.          ║
  ║                                              ║
  ║   Run  jenfetch  for system info             ║
  ║   Run  flatpak install flathub <app>         ║
  ║        to install applications               ║
  ╚══════════════════════════════════════════════╝

root@jenteck:~# jenfetch --no-logo
OS       Jenteck OS 1.0 Server (x86_64)
Kernel   6.9.3-jenteck
Arch     x86_64
Uptime   0m 41s
Shell    bash
Packages 0 (flatpak)
CPU      Intel Xeon E5-2680 (8 cores)
RAM      214 MiB / 8192 MiB
Disk     1.2 GiB / 40 GiB (3%)
Server use cases

Minimal headless VM or container host
Learning how a Linux system is put together without any distro magic hiding the details
Lightweight Flatpak app host — install and run sandboxed apps without a full desktop
Base for your own custom server builds


Building
Both editions are built from this repository using the same build.sh script. The EDITION environment variable selects which one to produce.
Host requirements
You need a Debian or Ubuntu machine — physical, VM, or WSL2 — with internet access and roughly 30 GB of free space for the Desktop build, or 10 GB for Server.
bashsudo apt update
sudo apt install -y \
    build-essential bison flex texinfo gawk git wget curl \
    libelf-dev libssl-dev bc cpio cmake ninja-build \
    xorriso mtools genisoimage squashfs-tools dosfstools parted \
    grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin \
    python3 python3-pip \
    python3-gi python3-gi-cairo gir1.2-gtk-3.0

pip3 install --upgrade meson ninja
Clone
bashgit clone https://github.com/kingofvids/jenteck-os
cd jenteck-os
chmod +x build.sh
Build commands
bash# ── Desktop ──────────────────────────────────────────────
# 64-bit  (UEFI + BIOS)  ·  ~3–6 hours
./build.sh x86_64

# 32-bit  (BIOS)  ·  ~4–7 hours
./build.sh i686

# ── Server ───────────────────────────────────────────────
# 64-bit  ·  ~1–2 hours  (skips all X11 and XFCE4 phases)
EDITION=server ./build.sh x86_64

# 32-bit
EDITION=server ./build.sh i686

# ── Options ──────────────────────────────────────────────
# Control the number of parallel compile jobs (default: all cores)
JOBS=8 ./build.sh x86_64
JOBS=4 EDITION=server ./build.sh x86_64
Finished ISOs land in output/:
output/
├── jenteck-os-desktop-x86_64.iso
├── jenteck-os-desktop-i686.iso
├── jenteck-os-server-x86_64.iso
└── jenteck-os-server-i686.iso
Resuming an interrupted build
Every phase is numbered and independent. If a build fails or you close the terminal, resume from where it stopped:
bash# Resume Desktop from the XFCE4 phase
START_PHASE=9 ./build.sh x86_64

# Resume Server from ISO assembly only
START_PHASE=13 EDITION=server ./build.sh x86_64
Build phases
#PhaseDesktopServer1Cross-Toolchain — Binutils 2.42, GCC 14.1, Glibc 2.39✓✓2Base System — BusyBox 1.36, Bash 5.2, util-linux, eudev✓✓3Linux Kernel — 6.9.3, USB/AHCI/NVMe/Wi-Fi/VirtIO✓✓4GRUB Bootloader — UEFI EFI image + BIOS core image✓✓5Flatpak — D-Bus → GLib → OSTree → Flatpak 1.15 (all source)✓✓6jenfetch — installed to /usr/bin/jenfetch✓✓7Branding — motd, os-release, init, profile, aliases✓✓8X11 Stack — Xorg, Mesa, GTK3, Cairo, Pango, fonts✓—9XFCE4 Desktop — all 13 components + VTE terminal✓—10LightDM — display manager + Jenteck GTK greeter✓—11Theme & Config — Jenteck-Dark, panel layout, terminal colours✓—12Graphical Installer — jenteck-install + polkit + desktop entry✓—13Initramfs — squashfs + overlayfs live boot✓✓14ISO Assembly — xorriso hybrid UEFI/BIOS ISO✓✓

Flash to USB
bash# Desktop
sudo dd if=output/jenteck-os-desktop-x86_64.iso of=/dev/sdX bs=4M status=progress && sync

# Server
sudo dd if=output/jenteck-os-server-x86_64.iso of=/dev/sdX bs=4M status=progress && sync
Replace /dev/sdX with your USB drive. Both ISOs are isohybrid — the same image boots from a USB stick, a DVD, or inside a VM with no modification.

Testing in a VM
bash# Desktop — UEFI (recommended)
qemu-system-x86_64 -m 2G \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom output/jenteck-os-desktop-x86_64.iso \
    -boot d -vga virtio

# Desktop — Legacy BIOS
qemu-system-x86_64 -m 2G \
    -cdrom output/jenteck-os-desktop-x86_64.iso -boot d

# Server — minimal, no display needed
qemu-system-x86_64 -m 512M \
    -cdrom output/jenteck-os-server-x86_64.iso \
    -boot d -nographic

# 32-bit Desktop
qemu-system-i386 -m 1G \
    -cdrom output/jenteck-os-desktop-i686.iso -boot d

Graphical Installer

Desktop edition only. Server users: partition manually and run grub-install + grub-mkconfig inside a chroot.

When running the live Desktop session, double-click Install Jenteck OS on the desktop, or run:
bashjenteck-install
The GTK3 wizard covers eight steps:
StepWhat it does1 — WelcomeOverview of what will be installed and requirements2 — Select DiskLive list of all drives — name, size, and model3 — Partition LayoutAuto: 512 MiB EFI + 2 GiB swap + remaining ext4 root. Or open a shell for manual partitioning.4 — Locale & TimezoneLanguage, timezone from a scrollable list, keyboard layout5 — User AccountUsername, password, hostname, optional autologin toggle6 — SummaryComplete review of every choice — nothing is written to disk until you confirm7 — InstallingLive scrolling log: partition → format → copy files → write fstab → create user → install GRUB8 — CompleteClick Reboot to boot into your new system, or stay in the live session
GRUB is installed for both UEFI and Legacy BIOS in a single pass — the installed system will boot on any machine regardless of firmware type.

Installing apps
Flathub is pre-configured on both editions. After first boot into your installed system:
bash# One-time setup (usually already done, but run if needed)
flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

# Install apps from Flathub
flatpak install flathub org.mozilla.firefox
flatpak install flathub org.videolan.VLC
flatpak install flathub org.gimp.GIMP
flatpak install flathub com.spotify.Client
flatpak install flathub com.visualstudio.code
flatpak install flathub org.kde.kdenlive

# Run an app
flatpak run org.mozilla.firefox

# Search for apps
flatpak search music
These aliases are pre-loaded in /etc/profile on both editions:
bashfp           # short for flatpak
fpinstall    # flatpak install flathub
fpsearch     # flatpak search
fplist       # flatpak list
fprun        # flatpak run

jenfetch
jenfetch is a pure-Bash system info tool with no external dependencies beyond standard coreutils. On the Desktop edition it runs automatically when you open a terminal. On the Server edition you call it directly.
bashjenfetch            # full output with Jenteck logo (works in any colour terminal)
jenfetch --no-logo  # info only — good for SSH sessions and scripts
jenfetch --version  # print version and exit
It reports: OS name and version, kernel, architecture, uptime, shell, installed Flatpak packages, CPU model and core count, RAM used/total, disk used/total, and terminal type.

Repository layout
jenteck-os/
├── build.sh                          ← Entry point — run this
├── scripts/
│   ├── versions.sh                   ← Every package version in one place
│   ├── functions.sh                  ← Shared helpers (banner, fetch, xtract)
│   ├── 01-toolchain.sh               ← GCC cross-compiler + Glibc
│   ├── 02-base-system.sh             ← BusyBox, Bash, util-linux, eudev
│   ├── 03-kernel.sh                  ← Linux 6.9.3 + kernel modules
│   ├── 04-bootloader.sh              ← GRUB 2 UEFI + BIOS images
│   ├── 05-flatpak.sh                 ← Full Flatpak stack built from source
│   ├── 06-jenfetch-config.sh         ← jenfetch, branding, installer phase fn
│   ├── 07a-x11-stack.sh              ← [Desktop] Xorg, Mesa, GTK3, Cairo, Pango
│   ├── 07b-xfce4.sh                  ← [Desktop] XFCE4, LightDM, theme, defaults
│   └── 08-initramfs-iso.sh           ← Initramfs + xorriso hybrid ISO
├── config/
│   ├── meson-cross-x86_64.txt        ← Meson cross-compile definition (64-bit)
│   └── meson-cross-i686.txt          ← Meson cross-compile definition (32-bit)
├── rootfs-overlay/
│   └── usr/
│       ├── bin/
│       │   ├── jenfetch              ← jenfetch (pure Bash, ~200 lines)
│       │   └── jenteck-install       ← [Desktop] GTK3 installer (Python 3)
│       └── share/
│           ├── applications/
│           │   └── jenteck-install.desktop
│           └── polkit-1/actions/
│               └── uk.co.jenteck.install.policy
└── output/                           ← Generated ISOs (not tracked in git)
To upgrade any component, edit scripts/versions.sh — all download URLs and configure flags are derived from those variables, so a version bump is a one-line change.

The Jenteck ecosystem
Jenteck OS is one part of a broader personal project:
ProjectWhat it isJenteck OSThis — a from-scratch Linux distributionJenteck BrowserCustom browser with jtck:// protocol and .brs TLDJenteck AI (Planet)Personal AI assistant — Planet 1.0 to 3.0, Gemini-backedJenteck App StoreCurated catalogue of 60+ apps across 8 categoriesjenfetchSystem info tool, part of this repository
🌍 jenteck.co.uk

Licence
Build scripts and tooling in this repository: MIT
All compiled third-party software — the Linux kernel, GCC, XFCE4, GTK, Mesa, Flatpak, and everything else — retains its own upstream licence (GPL-2.0, GPL-3.0, LGPL, MIT, etc.). See each project's source for details.

<div align="center">
Made by kingofvids · jenteck.co.uk
</div>
