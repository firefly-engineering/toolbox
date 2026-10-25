# typescript-toolchain

## Overview

Bundles the TypeScript compiler with Node.js, Biome, Bun and (from version 4) pnpm. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.

## Interface

- `default.nix`: `toolboxLib.buildToolchain { name = "typescript-toolchain"; dataPath = ./data.json; }`.
- `data.json`: versions `1`..`5`, `_meta.default` = `5` (`typescript 7.0.2`, `nodejs 24.20.0`, `biome 2.5.2`, `bun 1.4.2`, `pnpm 12.3.4`). No `_meta.releases`.
- Components: [typescript](../typescript/EGM.md), [nodejs](../nodejs/EGM.md), [biome](../biome/EGM.md), [bun](../bun/EGM.md), [pnpm](../pnpm/EGM.md) (versions `4`+).
- Version `5` pins TypeScript 7 (`ts7` builder: native `tsc`, no `tsserver`); versions `1`..`4` pin `6.0.3` (`tsc` + `tsserver`).

## Invariants

- Every component key must be a toolbox package name, and every pin a version that package defines; `nix flake check` fails on a pin resolving to nothing.
- Versions are immutable: a component bump adds a new toolchain version rather than editing an existing one.
- Available only on systems where every component is available (`buildToolchain` intersects their platforms).
- The registry stamp has `kind = "toolchain"` and `components` = the per-version pins.

## Side Effects

- None of its own; building it builds or substitutes its components.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#typescript-toolchain.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
