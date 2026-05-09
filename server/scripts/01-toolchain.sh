#!/usr/bin/env bash
# =============================================================================
#  Phase 1 — Cross-Compilation Toolchain
#  Builds a minimal GCC cross-compiler targeting the Jenteck rootfs.
#  This is intentionally minimal — just enough to compile the base system.
# =============================================================================

build_toolchain() {
    banner "Phase 1 — Building Cross-Toolchain (${ARCH})"

    local TC="${BUILD_DIR}/toolchain"
    local WORK="${BUILD_DIR}/work"
    local TARGET
    [[ "$ARCH" == "x86_64" ]] && TARGET="x86_64-jenteck-linux-gnu" \
                               || TARGET="i686-jenteck-linux-gnu"
    export PATH="${TC}/bin:${PATH}"

    # ── Fetch sources ────────────────────────────────────────────────────────
    fetch "${GNU_MIRROR}/binutils/binutils-${BINUTILS_VER}.tar.xz"
    fetch "${GNU_MIRROR}/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"
    fetch "${GNU_MIRROR}/glibc/glibc-${GLIBC_VER}.tar.xz"
    fetch "${GNU_MIRROR}/mpfr/mpfr-${MPFR_VER}.tar.xz"
    fetch "${GNU_MIRROR}/gmp/gmp-${GMP_VER}.tar.xz"
    fetch "${GNU_MIRROR}/mpc/mpc-${MPC_VER}.tar.gz"

    # ── 1.1 Binutils pass 1 ─────────────────────────────────────────────────
    info "Building Binutils (pass 1) …"
    xtract "binutils-${BINUTILS_VER}.tar.xz"
    mkdir -p "${WORK}/binutils-pass1-build"
    pushd "${WORK}/binutils-pass1-build" >/dev/null
      "../binutils-${BINUTILS_VER}/configure" \
        --prefix="${TC}" --target="${TARGET}" \
        --with-sysroot="${ROOTFS}" --disable-nls --disable-werror \
        --enable-gprofng=no
      make -j"${JOBS}"
      make install
    popd >/dev/null

    # ── 1.2 GCC pass 1 (C only, no libc yet) ────────────────────────────────
    info "Building GCC (pass 1, C only) …"
    xtract "gcc-${GCC_VER}.tar.xz"
    # Bundle MPFR/GMP/MPC inside GCC source
    tar -xf "${BUILD_DIR}/sources/mpfr-${MPFR_VER}.tar.xz" -C "${WORK}/gcc-${GCC_VER}"
    ln -sf "mpfr-${MPFR_VER}" "${WORK}/gcc-${GCC_VER}/mpfr"
    tar -xf "${BUILD_DIR}/sources/gmp-${GMP_VER}.tar.xz" -C "${WORK}/gcc-${GCC_VER}"
    ln -sf "gmp-${GMP_VER}" "${WORK}/gcc-${GCC_VER}/gmp"
    tar -xf "${BUILD_DIR}/sources/mpc-${MPC_VER}.tar.gz" -C "${WORK}/gcc-${GCC_VER}"
    ln -sf "mpc-${MPC_VER}" "${WORK}/gcc-${GCC_VER}/mpc"

    local GCC_OPTS=(
        --prefix="${TC}" --target="${TARGET}" --with-sysroot="${ROOTFS}"
        --with-newlib --without-headers --enable-languages=c,c++
        --disable-nls --disable-shared --disable-multilib
        --disable-decimal-float --disable-threads --disable-libatomic
        --disable-libgomp --disable-libquadmath --disable-libssp
        --disable-libvtv --disable-libstdcxx --enable-default-pie
    )
    [[ "$ARCH" == "i686" ]] && GCC_OPTS+=(--with-arch=i686)

    mkdir -p "${WORK}/gcc-pass1-build"
    pushd "${WORK}/gcc-pass1-build" >/dev/null
      "../gcc-${GCC_VER}/configure" "${GCC_OPTS[@]}"
      make -j"${JOBS}" all-gcc all-target-libgcc
      make install-gcc install-target-libgcc
    popd >/dev/null

    # ── 1.3 Linux kernel headers (for Glibc) ────────────────────────────────
    info "Installing Linux headers …"
    fetch "${KERNEL_MIRROR}/linux-${LINUX_VER}.tar.xz"
    xtract "linux-${LINUX_VER}.tar.xz"
    pushd "${WORK}/linux-${LINUX_VER}" >/dev/null
      local KARCH; [[ "$ARCH" == "x86_64" ]] && KARCH="x86_64" || KARCH="i386"
      make ARCH="${KARCH}" headers_install INSTALL_HDR_PATH="${ROOTFS}/usr"
    popd >/dev/null

    # ── 1.4 Glibc (target) ──────────────────────────────────────────────────
    info "Building Glibc (target) …"
    xtract "glibc-${GLIBC_VER}.tar.xz"
    mkdir -p "${WORK}/glibc-build"
    pushd "${WORK}/glibc-build" >/dev/null
      local GLIBC_OPTS=(
          --prefix=/usr --host="${TARGET}" --build="${MACHTYPE}"
          --enable-kernel=4.14 --with-headers="${ROOTFS}/usr/include"
          libc_cv_slibdir=/usr/lib
      )
      [[ "$ARCH" == "i686" ]] && GLIBC_OPTS+=(--host=i686-linux-gnu)
      "../glibc-${GLIBC_VER}/configure" "${GLIBC_OPTS[@]}"
      make -j"${JOBS}"
      make DESTDIR="${ROOTFS}" install
    popd >/dev/null

    info "✔ Toolchain complete → ${TC}/bin/${TARGET}-gcc"
}
