# nil

## Overview

`nil` Nix language server built from the `oxalica/nil` date tag via `toolboxLib.buildRustPackage`, with version-namespaced vendored `Cargo.lock` files.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.nil`: `versions` = 2025-06-13, 2026-07-23 (date-tag versions); `default` = `2026-07-23` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildRustPackage { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/nil`.
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (default version pins Rust `1.97.0`).
- `rev = { version }: version` (tags are bare dates, no `v` prefix).
- Vendored lockfiles (data, no code): `Cargo-2025-06-13.lock`, `Cargo-2026-07-23.lock`, supplied as `cargoLock.lockFile = ./. + "/Cargo-${version}.lock"`.

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball) and `rust` (a version key of `packages/rust/data.json`).
- No `cargoHash` in `data.json`: each version needs a matching `Cargo-<version>.lock` on disk; reading upstream's lock from `src` would be import-from-derivation.
- `CFG_RELEASE` is set to the version; `nix` (nixpkgs) is a native build input because the `builtin` crate shells out to `nix` at build time.

## Side Effects

- Fixed-output fetch of the `oxalica/nil` source tarball and crate dependencies at build time only; evaluation is offline.
- `preBuild` exports a temporary `NIX_STATE_DIR` inside the sandbox for the build-time `nix` invocation.

## Verification

Run from the repository root:

```bash
nix build --no-link .#nil.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
