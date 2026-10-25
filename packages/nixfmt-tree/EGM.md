# nixfmt-tree

## Overview

Zero-setup Nix formatter: toolbox's pinned `treefmt` wrapped with nixpkgs `nixfmt` and a generated `treefmt.toml`; a custom `symlinkJoin` builder.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.nixfmt-tree`: `versions` = 2.5.0; `default` = `2.5.0` (version keys track treefmt).
- Builder: custom `builders.default` returning `pkgs.symlinkJoin` over `toolbox.treefmt.versions.${versionData.treefmt}`.
- Installs `bin/treefmt` wrapped (`makeBinaryWrapper`) with `nixfmt` on `PATH` and `--config-file <store treefmt.toml>`; config formats `*.nix` with `nixfmt`, `on-unmatched = "info"`.
- Cross-package dependency: `toolbox.treefmt` (default pins treefmt 2.5.0).
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.

## Invariants

- Each version entry carries only `treefmt`, a version key of `packages/treefmt/data.json`; no source hash of its own.
- `nixfmt` comes from the pinned nixpkgs (Haskell; no toolbox builder).
- The generated config mirrors nixpkgs' `nixfmt-tree` treefmt config.

## Side Effects

- None of its own at build time beyond the component derivations' fixed-output fetches.
- At runtime `treefmt` rewrites `*.nix` files in the tree it is run on.

## Verification

Run from the repository root:

```bash
nix build --no-link .#nixfmt-tree.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
