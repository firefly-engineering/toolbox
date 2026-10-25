# qmk_hid

## Overview

Packages [qmk_hid](https://github.com/FrameworkComputer/qmk_hid), a CLI to talk to QMK devices over their raw HID interface, built from source with the toolbox Rust toolchain.

## Interface

- `default.nix`: `toolboxLib.buildRustPackage` (owner `FrameworkComputer`, repo `qmk_hid`, default rev `v<version>`), passed to `toolboxLib.buildPackage { name = "qmk_hid"; }`.
- `data.json`: version `0.1.13` (`_meta.default`), built with toolbox rust `1.95.0`.
- `Cargo-<version>.lock` (today `Cargo-0.1.13.lock`): vendored lockfile passed as `cargoLock.lockFile`.
- Output: `bin/qmk_hid`.
- Cross-package deps: `toolbox.rust.versions.<rust>` ([rust](../rust/EGM.md)).
- Platforms: not declared; there is no `meta.platforms`. The OS split only picks build inputs: Linux adds `pkg-config` + `udev`, Darwin adds `apple-sdk_15`.

## Invariants

- Each version entry needs `sha256` (`--unpack` hash of the tag) and `rust` (a toolbox rust version). It has no `cargoHash`: dependencies are pinned by the vendored lock instead.
- Locks are version-namespaced: each version needs its own `Cargo-<version>.lock` next to `default.nix`.
- Tests are not run (`doCheck = false`, set by the helper).

## Side Effects

- Build time only: fixed-output fetch of the GitHub source and the crates named in the vendored lock.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#qmk_hid.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
