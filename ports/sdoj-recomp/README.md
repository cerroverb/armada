# SDOJ-Recomp for Linux AArch64

Build kit for a Linux AArch64 (ARM64) build of
[SDOJ-Recomp](https://github.com/eandis/SDOJ-Recomp), the ReXGlue static recompilation of the Xbox 360 version of
DoDonPachi SaiDaiOuJou. It pins SDOJ-Recomp v1.51.4 (`cf0afe1`), applies the patches below, builds with Clang, and
packages `out/sdoj-recomp-linux-arm64.tar.gz`.

No game data is included. The game needs your own Xbox 360 dump and the TU1 file, as described in SDOJ-Recomp's
README (copied into the package as `README-SDOJ-Recomp.md`).

## What the port changes

SDOJ-Recomp already has a `linux-arm64-release` preset, but the SDK copy it bundles and its generated code predate
several AArch64 fixes. Each change below is either an upstream rexglue-sdk fix or code ported from
espgaluda2-recomp, which runs on Linux AArch64 with the same SDK copy.

| Change | Source | Why it matters on AArch64 |
| --- | --- | --- |
| `patches/0001-aarch64-fctid-and-rounding-mode.patch` | espgaluda2-recomp sdk-patches/0011 (fctid from futari-nx) | `fctid` rounds in the guest's rounding mode (simde rounds half away from zero); `mffs` reads FPCR's rounding mode back in the right order |
| `patches/0002-ffmpeg-hidden-visibility-arm64.patch` | upstream rexglue-sdk `d82ec28` | `librexruntime.so` does not link on Linux AArch64 without it |
| `patches/0003-xex-delta-patch-memmove.patch` | upstream rexglue-sdk `85aa46b` | SDOJ applies `default.xexp` and the `.binp` TU1 delta patches at load time; the overlapping `memcpy` corrupts the patched image on AArch64 glibc |
| `patches/0004-threading-suspended-start-race.patch` | upstream rexglue-sdk `96bee61` | lost wakeup when a guest thread is created suspended and resumed at once |
| `patches/0005-multiwait-sleep-microseconds.patch` | espgaluda2-recomp sdk-patches/0009 (futari-nx) | the audio worker's wait spun a core (measured 67 % of a core on a Steam Deck) |
| `patches/0006-timer-queue-condition-variable.patch` | espgaluda2-recomp sdk-patches/0010 (futari-nx) | the timer queue spun (measured 14.5 % of a core on a Steam Deck) |
| `patches/0007-aarch64-vsl-right-shift.patch` | upstream rexglue-sdk `df2743b` (its intrinsics.h hunk) | the NEON `vsl` path shifted the carry the wrong way |
| `tools/update_generated_code.py`, barrier fences | output of upstream codegen `bd833a2` | the generated code had no fences for `sync`, `lwsync` and `eieio` (79 sites); x86-64's TSO hid this, AArch64 does not |
| `tools/update_generated_code.py`, `fctiwz` bound | output of upstream codegen `df2743b` | simde's portable `_mm_cvttsd_si32` returns INT_MIN at INT_MAX (1225 sites) |

The generated code is changed by a script instead of running codegen again, because codegen needs the game's XEX.
Each rewrite produces the same text the newer codegen emits for that instruction.

## Verification

Done in an x86-64 container (cross-compiled, run under qemu-user):

- The whole project builds and links for AArch64: `DoDonPachi SaiDaiOuJou`, `librexruntime.so`,
  `libTracyClient.so`, `libsaidaioujou_recomp_tu1_CA022100.so`, `libsaidaioujou_recomp_tu1_CA022110.so` and
  `tools/extract-xiso/extract-xiso`. Highest symbol versions needed: GLIBC_2.38, GLIBCXX_3.4.32.
- The SDK's PPC instruction tests (166 files, 1445 test cases, 5722 assertions) built for AArch64 and run under
  qemu-aarch64 give the same result as the x86-64 build: one failure on both, `vpkd3d128.test_float16_4_invalid_0`.
  Before patch 0007 and the `fctiwz` bound change, AArch64 had five more failures (`vsl` 1 to 4, `fctiwz_8`).
- The SDK unit tests fail the same 15 cases on AArch64 and x86-64.
- The program starts under qemu-aarch64 with Xvfb and Mesa lavapipe: GTK window, Vulkan device, swapchain, and the
  first-launch "Preparing game data" window.

Not verified here: the game itself. No game data was available, and nothing ran on ARM hardware. Under qemu with
software Vulkan, the setup window did not move on to its "Setup failed" message: GTK's idle callback, which delivers
the setup result, did not run while every software-rendered frame took longer than a frame interval.

## Building

### On an AArch64 machine

Needs CMake 3.25 or newer, Ninja, Clang 18 or newer, Python 3, git, pkg-config, and the development files SDOJ-Recomp
lists for Debian/Ubuntu (`libgtk-3-dev libx11-xcb-dev libvulkan-dev libasound2-dev libpulse-dev libpipewire-0.3-dev
libcurl4-openssl-dev`); the configure step checks for the `gtk+-3.0`, `x11-xcb` and `libcurl` pkg-config modules.

Then, with an unversioned `clang`:

```bash
CLANG_SUFFIX= ./build.sh
```

### Cross-compiling on x86-64 (Ubuntu 24.04)

```bash
sudo dpkg --add-architecture arm64
```

Restrict the existing Ubuntu sources to `Architectures: amd64`, add `ports.ubuntu.com/ubuntu-ports` for `arm64`, then:

```bash
sudo apt-get update
```

```bash
sudo apt-get install -y clang-20 lld-20 llvm-20 cmake ninja-build python3 git libstdc++-13-dev-arm64-cross libc6-dev-arm64-cross libgtk-3-dev:arm64 libx11-xcb-dev:arm64 libvulkan-dev:arm64 libasound2-dev:arm64 libpulse-dev:arm64 libpipewire-0.3-dev:arm64 libcurl4-openssl-dev:arm64
```

```bash
./build.sh
```

`build.sh` clones SDOJ-Recomp into `sdoj-src/`, applies the patches (already applied ones are skipped), runs
`tools/update_generated_code.py`, builds into `sdoj-src/out/build/linux-arm64-release`, and writes
`out/sdoj-recomp-linux-arm64.tar.gz`. A build runs about 1190 steps; the first cross-build here (4 cores, empty ccache) took about 16 minutes.

## Installing

Unpack the tarball anywhere, put the SDOJ ISO and the TU1 file next to `DoDonPachi SaiDaiOuJou`, and run it. The
first launch extracts the ISO into `game_data` and installs TU1. Settings and saves go to `user_data`. On Armada, it
can be added to Steam as a non-Steam game.
