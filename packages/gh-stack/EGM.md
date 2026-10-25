# gh-stack

## Overview
Packages the [`gh-stack`](https://github.com/github/gh-stack) GitHub CLI extension for stacked pull requests as a single prebuilt binary via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "gh-stack"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/github/gh-stack/releases/download/v<version>/<os>-<arch>` (bare binary, no unpack).
- Installs `$out/bin/gh-stack` (`meta.mainProgram = "gh-stack"`).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `0.2.1` (default), `0.1.1`, `0.1.0`, `0.0.7`, `0.0.3`, `0.0.2`, `0.0.1`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-file `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release binary. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#gh-stack.default` (or `.#gh-stack.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
