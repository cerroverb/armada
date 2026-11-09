#!/usr/bin/env bash
# Build SDOJ-Recomp (DoDonPachi SaiDaiOuJou, Xbox 360, ReXGlue) for Linux AArch64.
#
# Clones eandis/SDOJ-Recomp at a pinned commit into ./sdoj-src, applies patches/*.patch, brings the generated code up
# to two later upstream codegen changes (tools/update_generated_code.py), builds a Release, and packages
# out/sdoj-recomp-linux-arm64.tar.gz.
#
# On an AArch64 host it builds natively. On an x86-64 host it cross-compiles with cmake/aarch64-linux-gnu-clang.cmake,
# which needs the arm64 multiarch -dev packages (see README.md).
#
# Environment:
#   SDOJ_COMMIT   SDOJ-Recomp commit to build (default: the pinned one below)
#   CLANG_SUFFIX  suffix of clang/clang++ (default: -20; set to "" for unversioned clang)
#   JOBS          parallel jobs (default: nproc)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
SDOJ_REPO="https://github.com/eandis/SDOJ-Recomp.git"
SDOJ_COMMIT="${SDOJ_COMMIT:-cf0afe107d02fa16980e8c8f90a5969aafac81a7}"  # v1.51.4, 2026-10-31
CLANG_SUFFIX="${CLANG_SUFFIX--20}"
JOBS="${JOBS:-$(nproc)}"
src="$here/sdoj-src"
build="$src/out/build/linux-arm64-release"

echo "=== source ==="
if [ ! -d "$src/.git" ]; then
    git clone "$SDOJ_REPO" "$src"
fi
git -C "$src" fetch --quiet origin "$SDOJ_COMMIT" 2>/dev/null || git -C "$src" fetch --quiet origin
if [ "$(git -C "$src" rev-parse HEAD)" != "$SDOJ_COMMIT" ]; then
    if [ -n "$(git -C "$src" status --porcelain --untracked-files=no)" ]; then
        echo "sdoj-src has local changes and is not at $SDOJ_COMMIT; remove it or check it out by hand" >&2
        exit 1
    fi
    git -C "$src" checkout --quiet --detach "$SDOJ_COMMIT"
fi

echo "=== patches ==="
for p in "$here"/patches/*.patch; do
    name="$(basename "$p")"
    if git -C "$src" apply --reverse --check "$p" 2>/dev/null; then
        echo "already applied: $name"
    else
        git -C "$src" apply "$p"
        echo "applied: $name"
    fi
done
python3 -I "$here/tools/update_generated_code.py" "$src/generated"

echo "=== configure ==="
cmake_args=(
    -S "$src" -B "$build" -G Ninja
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_C_FLAGS=-march=armv8-a
    -DCMAKE_CXX_FLAGS=-march=armv8-a
)
if command -v ccache >/dev/null; then
    cmake_args+=(-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
fi
case "$(uname -m)" in
    aarch64|arm64)
        cmake_args+=(-DCMAKE_C_COMPILER="clang$CLANG_SUFFIX" -DCMAKE_CXX_COMPILER="clang++$CLANG_SUFFIX")
        ;;
    *)
        cmake_args+=(-DCMAKE_TOOLCHAIN_FILE="$here/cmake/aarch64-linux-gnu-clang.cmake"
                     -DSDOJ_CLANG_SUFFIX="$CLANG_SUFFIX")
        ;;
esac
cmake "${cmake_args[@]}"

echo "=== build ==="
cmake --build "$build" --parallel "$JOBS"

echo "=== package ==="
pkg_root="$here/out/package"
pkg="$pkg_root/sdoj-recomp-linux-arm64"
rm -rf "$pkg_root"
mkdir -p "$pkg/tools/extract-xiso"
cp -L "$build/DoDonPachi SaiDaiOuJou" "$pkg/"
cp -L "$build"/*.so "$pkg/"
cp "$build/tools/extract-xiso/extract-xiso" "$build/tools/extract-xiso/LICENSE.TXT" "$pkg/tools/extract-xiso/"
cp "$src/README.md" "$pkg/README-SDOJ-Recomp.md"
cp "$here/README.md" "$pkg/README-aarch64.md"
file "$pkg/DoDonPachi SaiDaiOuJou" "$pkg"/*.so "$pkg/tools/extract-xiso/extract-xiso"
tar --owner=0 --group=0 -C "$pkg_root" -czf "$here/out/sdoj-recomp-linux-arm64.tar.gz" sdoj-recomp-linux-arm64
ls -l "$here/out/sdoj-recomp-linux-arm64.tar.gz"
