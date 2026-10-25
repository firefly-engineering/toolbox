# go-toolchain

## Overview
A toolchain meta-package that bundles a pinned set of Go tools into one `symlinkJoin` via `toolboxLib.buildToolchain`. It contains no build logic of its own.

## Interface
- `default.nix`: `toolboxLib.buildToolchain { inherit toolbox pkgs; name = "go-toolchain"; dataPath = ./data.json; }`.
- Registry stamp `kind = "toolchain"`, with `components` per version.
- `data.json`: integer-string versions; default `7`.
  - `7`: go 1.27.2, golangci-lint 2.15.0, gopls 0.24.0, gotestsum 1.13.0, go-licenses 2.0.1.
  - `6`: go 1.27.1, golangci-lint 2.12.2, gopls 0.23.0, gotestsum 1.13.0, go-licenses 2.0.1.
  - `5`: go 1.26.4, golangci-lint 2.12.2, gopls 0.22.0, gotestsum 1.13.0, go-licenses 2.0.1.
  - `4`: go 1.26.2, golangci-lint 2.11.3, gopls 0.21.1, gotestsum 1.13.0, go-licenses 2.0.1.
  - `1`-`3`: go 1.26.0 / 1.26.1 / 1.26.2 with golangci-lint 2.11.3 and gopls 0.21.1 only.
- Components: [go](../go/EGM.md), [golangci-lint](../golangci-lint/EGM.md), [gopls](../gopls/EGM.md), [gotestsum](../gotestsum/EGM.md), [go-licenses](../go-licenses/EGM.md).
- Output: union of the components' `bin/` (and other) trees; available only on systems every component supports.

## Invariants
- Component keys must match toolbox package names exactly and each pin must be an existing version of that package (`nix flake check` fails otherwise).
- No `_meta.releases`: there is no upstream for a toolchain.

## Side Effects
- None of its own; building it builds or substitutes each component. No runtime side effects.

## Verification
- Run: `nix build .#go-toolchain.default` (or `.#go-toolchain.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
