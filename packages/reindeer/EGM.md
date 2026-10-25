# reindeer

## Overview

Packages [reindeer](https://github.com/facebookincubator/reindeer), which generates Buck build rules from Cargo, built from source with the toolbox Rust toolchain.

## Interface

- `default.nix`: `toolboxLib.buildRustPackage` (owner `facebookincubator`, repo `reindeer`, default rev `v<version>`; tags are v-prefixed calver), passed to `toolboxLib.buildPackage { name = "reindeer"; }`.
- `data.json`: versions `2026.09.21.00` (`_meta.default`, rust `1.98.1`), `2026.04.27.00` (rust `1.95.0`), `2026.03.09.00` (rust `1.92.0`).
- Output: `bin/reindeer`.
- Cross-package deps: `toolbox.rust.versions.<rust>` ([rust](../rust/EGM.md)).
- Build inputs: `pkg-config`, `openssl`.

## Invariants

- Each version entry needs `sha256` (`--unpack` hash of the tag), `cargoHash` (vendored crate hash) and `rust` (a toolbox rust version).
- Tests are not run (`doCheck = false`, set by the helper).

## Side Effects

- Build time only: fixed-output fetches of the GitHub source and the cargo vendor tree.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#reindeer.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
