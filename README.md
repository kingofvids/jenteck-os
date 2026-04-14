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

## Build

```bash
make all
```

## Test in QEMU

```bash
scripts/run-qemu.sh
```

## Structure

- `build/`: build orchestration scripts
- `rootfs/`: initramfs root filesystem templates
- `scripts/`: runtime and helper scripts
- `output/`: generated build artifacts (ignored in git)
