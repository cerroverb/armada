# Cross toolchain: x86-64 host -> Linux AArch64, Clang + lld, Debian/Ubuntu multiarch arm64 libraries
# (dpkg --add-architecture arm64; libgtk-3-dev:arm64 etc.). See ../README.md.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(_triple aarch64-linux-gnu)

set(SDOJ_CLANG_SUFFIX "-20" CACHE STRING "Suffix of the clang/clang++/llvm-ar binaries")
set(CMAKE_C_COMPILER clang${SDOJ_CLANG_SUFFIX})
set(CMAKE_CXX_COMPILER clang++${SDOJ_CLANG_SUFFIX})
set(CMAKE_ASM_COMPILER clang${SDOJ_CLANG_SUFFIX})
set(CMAKE_C_COMPILER_TARGET ${_triple})
set(CMAKE_CXX_COMPILER_TARGET ${_triple})
set(CMAKE_ASM_COMPILER_TARGET ${_triple})
set(CMAKE_AR llvm-ar${SDOJ_CLANG_SUFFIX})
set(CMAKE_RANLIB llvm-ranlib${SDOJ_CLANG_SUFFIX})
set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=lld")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-fuse-ld=lld")

set(CMAKE_LIBRARY_ARCHITECTURE ${_triple})
set(CMAKE_FIND_ROOT_PATH /usr/${_triple})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} "/usr/lib/${_triple}/pkgconfig:/usr/share/pkgconfig")

# Lets custom commands and tests run target binaries through qemu-user when it is installed. The multiarch arm64
# loader and libraries live under /, so qemu's prefix is /.
find_program(_qemu_aarch64 qemu-aarch64)
if(_qemu_aarch64 AND EXISTS /lib/ld-linux-aarch64.so.1)
    set(CMAKE_CROSSCOMPILING_EMULATOR ${_qemu_aarch64};-L;/)
endif()
