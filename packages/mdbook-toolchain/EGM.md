# mdbook-toolchain

## Overview

mdBook plus its preprocessors (admonish, mermaid, footnote, graphviz) assembled with `toolboxLib.buildToolchain`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.mdbook-toolchain` (stamp `kind = "toolchain"`, `components` per version): `versions` = 1; `default` = `1`.
- Builder: `toolboxLib.buildToolchain { inherit toolbox pkgs; name = "mdbook-toolchain"; dataPath = ./data.json; }`; no custom Nix logic.
- Default composition: `mdbook` 0.4.52, `mdbook-admonish` 1.20.0, `mdbook-mermaid` 0.16.2, `mdbook-footnote` 0.1.1, `mdbook-graphviz` 0.2.1.

## Invariants

- Every component key is a toolbox package name and every pin is a version key in that package's `data.json`; `nix flake check` fails otherwise.
- Versions are integer strings; a new composition is a new version key, existing ones are never edited.
- Available systems are the intersection of the components' `meta.platforms`.
- Version 1 pins `mdbook` 0.4.52, not the `mdbook` package default (0.5.3).

## Side Effects

- None of its own: builds only symlink farms over component derivations, whose fetches are fixed-output.

## Verification

Run from the repository root:

```bash
nix build --no-link .#mdbook-toolchain.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
