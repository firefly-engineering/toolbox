# js-toolchain

## Overview

JavaScript toolchain (`nodejs`, `biome`, `bun`, `pnpm`) assembled with `toolboxLib.buildToolchain`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.js-toolchain` (stamp `kind = "toolchain"`, `components` per version): `versions` = 1 .. 7; `default` = `7`.
- Builder: `toolboxLib.buildToolchain { inherit toolbox pkgs; name = "js-toolchain"; dataPath = ./data.json; }`; no custom Nix logic.
- Default composition: `nodejs` 24.20.0, `biome` 2.5.2, `bun` 1.4.2, `pnpm` 12.3.4.

## Invariants

- Every component key is a toolbox package name and every pin is a version key in that package's `data.json`; `nix flake check` fails otherwise.
- Versions are integer strings; a new composition is a new version key, existing ones are never edited.
- Available systems are the intersection of the components' `meta.platforms`.
- `pnpm` ships no x86_64-darwin binary, so in versions 6 and 7 (the only ones with a `pnpm` component) the intersection excludes x86_64-darwin (which the flake does not advertise anyway). Versions 1–5 have no `pnpm` component.

## Side Effects

- None of its own: builds only symlink farms over component derivations, whose fetches are fixed-output.

## Verification

Run from the repository root:

```bash
nix build --no-link .#js-toolchain.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
