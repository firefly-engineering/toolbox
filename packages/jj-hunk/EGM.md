# jj-hunk

## Overview

`jj-hunk` built from the `laulauland/jj-hunk` GitHub tag with toolbox's pinned Rust via `toolboxLib.buildRustPackage`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.jj-hunk`: `versions` = 0.4.1, 0.5.1; `default` = `0.5.1` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildRustPackage { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/jj-hunk`.
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (default version pins Rust `1.95.0`).
- Opts in to vendored patches: `cargoPatches = toolboxLib.resolvePatches ./. versionData` (empty when `patches` is absent).
- `patches/` (no code): `patches/sigma-dev-0.4.1.patch`, used only by version 0.4.1.

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball), `cargoHash` and `rust` (a version key of `packages/rust/data.json`).
- Dependencies are pinned by upstream's `Cargo.lock` via the fixed-output `cargoHash`.
- Patch files are version-namespaced; `patches[].file` must exist on disk (checked by `nix flake check`), `patches[].source` is regeneration metadata for `/manage-patches` only.

## Side Effects

- Fixed-output fetch of the `laulauland/jj-hunk` source tarball and crate dependencies at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#jj-hunk.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
