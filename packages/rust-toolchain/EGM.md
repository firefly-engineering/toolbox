# rust-toolchain

## Overview

Bundles the Rust toolchain, its language server and `cargo-edit`. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.

## Interface

- `default.nix`: `toolboxLib.buildToolchain { name = "rust-toolchain"; dataPath = ./data.json; }`.
- `data.json`: versions `1`..`5`, `_meta.default` = `5` (`rust 1.98.1`, `rust-analyzer 2026-07-06`, `cargo-edit 0.13.9`). No `_meta.releases`.
- Components: [rust](../rust/EGM.md), [rust-analyzer](../rust-analyzer/EGM.md), [cargo-edit](../cargo-edit/EGM.md).

## Invariants

- Every component key must be a toolbox package name, and every pin a version that package defines; `nix flake check` fails on a pin resolving to nothing.
- Versions are immutable: a component bump adds a new toolchain version rather than editing an existing one.
- Available only on systems where every component is available (`buildToolchain` intersects their platforms).
- The registry stamp has `kind = "toolchain"` and `components` = the per-version pins.

## Side Effects

- None of its own; building it builds or substitutes its components.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#rust-toolchain.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
