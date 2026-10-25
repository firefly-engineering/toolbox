# vitaly

## Overview

Packages [vitaly](https://github.com/bskaplou/vitaly), a Vial-compatible CLI for QMK keyboards, built from source with the toolbox Rust toolchain.

## Interface

- `default.nix`: `toolboxLib.buildRustPackage` (owner `bskaplou`, repo `vitaly`, default rev `v<version>`), passed to `toolboxLib.buildPackage { name = "vitaly"; }`.
- `data.json`: version `0.1.32` (`_meta.default`), built with toolbox rust `1.95.0`.
- `Cargo.lock`: vendored lockfile passed as `cargoLock.lockFile`.
- Output: `bin/vitaly`.
- Cross-package deps: `toolbox.rust.versions.<rust>` ([rust](../rust/EGM.md)).
- Platforms: not declared; there is no `meta.platforms`. The OS split only picks build inputs: Linux adds `pkg-config` + `udev`, Darwin adds `apple-sdk_15`.

## Invariants

- Each version entry needs `sha256` (`--unpack` hash of the tag) and `rust` (a toolbox rust version). It has no `cargoHash`: dependencies are pinned by the vendored `Cargo.lock` instead.
- The vendored lock is a shared, non-version-namespaced `Cargo.lock`, so a new version needs the lock replaced (or namespaced) in step.
- `meta` sets no `license`.
- Tests are not run (`doCheck = false`, set by the helper).

## Side Effects

- Build time only: fixed-output fetch of the GitHub source and the crates named in `Cargo.lock`.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#vitaly.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
