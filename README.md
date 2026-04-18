# Jenteck OS

Jenteck OS is a lightweight Linux distribution project built from upstream Linux kernel and BusyBox.
This repository contains a reproducible build system for a minimal, initramfs-based distro named Jenteck OS.

## What is included

- Linux kernel build orchestration
- BusyBox-based root filesystem
- custom init script and minimal `/etc` templates
- QEMU boot helper for testing
- build automation via `make`

## Requirements

Install the required packages before building. On Debian/Ubuntu, run:

```bash
sudo apt update
sudo apt install -y build-essential flex bison libncurses-dev libssl-dev libelf-dev bc cpio xz-utils curl git qemu-system-x86
```

Required tools:
- bash, curl, tar, xz, gzip, make, gcc, git
- `flex`, `bison`, `bc`, `cpio`
- `qemu-system-x86_64` (optional for testing)

## Platform-Specific Instructions

### Windows

To build and run Jenteck OS on Windows, use Windows Subsystem for Linux (WSL).

1. Install WSL2 with Ubuntu: Open PowerShell as Administrator and run `wsl --install -d Ubuntu`, or install from the Microsoft Store.
2. Launch the Ubuntu terminal and follow the Debian/Ubuntu instructions above.

### macOS

On macOS, use Homebrew to install most dependencies.

1. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Install required packages:

```bash
brew install qemu gcc make bison flex ncurses openssl bc cpio xz curl git
```

Note: The `elfutils` package (providing `libelf.h`) is Linux-specific and not available on macOS via Homebrew. To build the Linux kernel, you have two options:

- **Option 1: Build elfutils from source** (advanced):
  ```bash
  git clone https://sourceware.org/git/elfutils.git
  cd elfutils
  autoreconf -i -f
  ./configure --prefix=/usr/local
  make
  sudo make install
  ```

- **Option 2: Use Docker** (recommended for simplicity):
  Install Docker for Mac, then run the build in an Ubuntu container:
  ```bash
  docker run --rm -v $(pwd):/workspace -w /workspace ubuntu:20.04 bash -c "
  apt update && apt install -y build-essential flex bison libncurses-dev libssl-dev libelf-dev bc cpio xz-utils curl git &&
  make all
  "
  ```

### Arch Linux

On Arch Linux, install the required packages using pacman:

```bash
sudo pacman -S base-devel flex bison ncurses openssl libelf bc cpio xz curl git qemu-system-x86_64
```

Then proceed with the build instructions below.

## Build

Build the kernel, BusyBox-based root filesystem, and initramfs image:

```bash
make all
```

The generated artifacts are written to `output/`:

- `output/bzImage`
- `output/jenteck-initramfs.cpio.gz`

## Run in QEMU

Start the built image with the helper script:

```bash
./scripts/run-qemu.sh
```

This uses `qemu-system-x86_64` and boots Jenteck OS directly from the built kernel and initramfs.

If you need to stop QEMU, use the terminal where it is running and press `Ctrl+C`, or terminate the process with:

```bash
pkill -f 'qemu-system-x86_64 -kernel.*output/bzImage'
```

## Structure

- `build/`: build orchestration scripts
- `rootfs/`: initramfs root filesystem templates
- `scripts/`: runtime and helper scripts
- `output/`: generated build artifacts (ignored in git)
