# platform-tools

## Overview

Solana `platform-tools` (sbpf rustc + LLVM for `cargo-build-sbf`) installed from prebuilt per-platform tarballs; a custom `mkDerivation` using `toolboxLib.unpackFlat`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.platform-tools`: `versions` = v1.54; `default` = `v1.54` (keys keep the `v` prefix).
- Asset URL: `https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-<os>-<arch>.tar.bz2`.
- Installs `rust/`, `llvm/` and `version.md` into `$out`.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.

## Invariants

- Each version nests `{ sha256 }` per system (raw `fetchurl` hash).
- Pinning it here replaces `cargo-build-sbf`'s own build-time download, keeping SBF builds offline and reproducible.
- `dontCheckForBrokenSymlinks` (dangling `lldb-argdumper`); on Linux `autoPatchelfHook` with `autoPatchelfIgnoreMissingDeps`, and `buildInputs` `cc.cc.lib`, `zlib`, `libxml2` and `ncurses`. The Linux path is noted in the source as not yet verified.

## Side Effects

- Fixed-output fetch of the per-system release tarball at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#platform-tools.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
