# buck2-toolchain

## Overview
Toolchain meta-package bundling buck2 with reindeer (Buck2 BUILD-file generator for Cargo) via `toolboxLib.buildToolchain` (`symlinkJoin`).

## Interface
- `default.nix`: `toolboxLib.buildToolchain { name = "buck2-toolchain"; dataPath = ./data.json; }`; stamp `kind = "toolchain"`.
- Versions: `5` (`_meta.default`: buck2 2026-09-15, reindeer 2026.09.21.00), `4` (2026-07-01, 2026.04.27.00), `3` (2026-04-15, 2026.04.27.00), `2` (2026-03-15, 2026.03.09.00), `1` (2025-12-01, 2026.03.09.00).
- Components: [buck2](../buck2/EGM.md) and [reindeer](../reindeer/EGM.md); the output links their `bin/` (`buck2`, `reindeer`).

## Invariants
- Component keys must match toolbox package names, and each pin must exist in that package's `data.json` (checked by `checkRegistry`).
- Toolchain versions are immutable integers; a new component pin gets a new toolchain version.
- Available platforms are the intersection of the components' platforms.

## Side Effects
- None of its own; builds pull in the component derivations.

## Verification
- Run: `nix build --no-link .#buck2-toolchain.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
