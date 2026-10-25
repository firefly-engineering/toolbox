# solidity-toolchain

## Overview

Bundles the Solidity compiler and Foundry. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.

## Interface

- `default.nix`: `toolboxLib.buildToolchain { name = "solidity-toolchain"; dataPath = ./data.json; }`.
- `data.json`: versions `1`..`3`, `_meta.default` = `3` (`solc 0.8.35`, `foundry v1.5.1`). No `_meta.releases`.
- Components: [solc](../solc/EGM.md), [foundry](../foundry/EGM.md).

## Invariants

- Every component key must be a toolbox package name, and every pin a version that package defines; `nix flake check` fails on a pin resolving to nothing.
- Versions are immutable: a component bump adds a new toolchain version rather than editing an existing one.
- Available only on systems where every component is available (`buildToolchain` intersects their platforms).
- The registry stamp has `kind = "toolchain"` and `components` = the per-version pins.

## Side Effects

- None of its own; building it builds or substitutes its components.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#solidity-toolchain.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
