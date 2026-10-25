# jj

## Overview

Jujutsu (`jj`) DVCS built from the `jj-vcs/jj` tag with toolbox's pinned Rust via `toolboxLib.buildRustPackage`; pname `jujutsu`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.jj`: `versions` = 0.38.0 .. 0.46.0 (9 versions); `default` = `0.46.0` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildRustPackage { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/jj` (only the `jj` bin target, `--bin jj`), man pages under `share/man`, bash/fish/zsh completions.
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (default version pins Rust `1.98.1`).

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball), `cargoHash` and `rust` (a version key of `packages/rust/data.json`).
- Dependencies are pinned by upstream's `Cargo.lock` via the fixed-output `cargoHash`.
- Links system `openssl`, `libgit2`, `libssh2`, `zstd` via pkg-config (`LIBGIT2_NO_VENDOR=1`, `ZSTD_SYS_USE_PKG_CONFIG=1`, `LIBSSH2_SYS_USE_PKG_CONFIG=1`).

## Side Effects

- Fixed-output fetch of the `jj-vcs/jj` source tarball and crate dependencies at build time only; evaluation is offline.
- `postInstall` runs the built `jj` to generate man pages and completions (inside the sandbox).

## Verification

Run from the repository root:

```bash
nix build --no-link .#jj.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
