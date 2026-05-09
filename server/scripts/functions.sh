#!/usr/bin/env bash
# =============================================================================
#  Jenteck OS — Build Functions
# =============================================================================

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'
CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'

banner() { echo -e "\n${CYN}${BLD}══════════════════════════════════════${RST}"; \
           echo -e "${CYN}${BLD}  $1${RST}"; \
           echo -e "${CYN}${BLD}══════════════════════════════════════${RST}\n"; }
info()   { echo -e "${GRN}[+]${RST} $*"; }
warn()   { echo -e "${YEL}[!]${RST} $*"; }
die()    { echo -e "${RED}[✗]${RST} $*" >&2; exit 1; }

# ── Host dependency check ────────────────────────────────────────────────────
check_host_deps() {
    banner "Checking host dependencies"
    local deps=(
        wget curl xorriso mtools genisoimage grub-pc-bin grub-efi-amd64-bin
        build-essential bison flex texinfo gawk libelf-dev libssl-dev bc
        cpio squashfs-tools dosfstools parted python3 git
    )
    local missing=()
    for d in "${deps[@]}"; do
        dpkg -s "$d" &>/dev/null || missing+=("$d")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Installing missing packages: ${missing[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y "${missing[@]}"
    fi
    info "All host dependencies satisfied."
}

# ── Directory setup ──────────────────────────────────────────────────────────
prepare_dirs() {
    banner "Preparing build directories"
    mkdir -p "${BUILD_DIR}"/{sources,toolchain,work}
    mkdir -p "${ROOTFS}"/{bin,sbin,lib,lib64,usr/{bin,sbin,lib,share},\
        etc/{jenteck,flatpak/remotes.d},var/{lib/flatpak,log},\
        proc,sys,dev,run,tmp,home,root,boot/grub,media,mnt}
    mkdir -p "${ISO_STAGING}"/{boot/grub,EFI/BOOT,live}
    mkdir -p "${OUTPUT}"
    info "Directories ready."
}

# ── Download helper ──────────────────────────────────────────────────────────
fetch() {
    local url="$1" dest="${BUILD_DIR}/sources/$(basename "$1")"
    [[ -f "$dest" ]] && { info "Already downloaded: $(basename "$1")"; return; }
    info "Downloading $(basename "$1") …"
    wget -q --show-progress -O "$dest" "$url" || die "Failed to download $url"
}

# ── Extract helper ───────────────────────────────────────────────────────────
xtract() {
    local tarball="${BUILD_DIR}/sources/$1" dest="${BUILD_DIR}/work"
    info "Extracting $1 …"
    tar -xf "$tarball" -C "$dest"
}

# ── chroot helper ────────────────────────────────────────────────────────────
jt_chroot() {
    sudo chroot "${ROOTFS}" /usr/bin/env -i \
        HOME=/root TERM=linux PATH=/usr/bin:/usr/sbin:/bin:/sbin \
        /bin/bash --login -c "$*"
}
