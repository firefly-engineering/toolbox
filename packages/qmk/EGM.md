# qmk

## Overview

Packages the [QMK CLI](https://github.com/qmk/qmk_cli) by overriding nixpkgs' `pkgs.qmk` Python package with a toolbox-pinned PyPI release plus vendored fork patches.

## Interface

- `default.nix`: `builders.default` = `pkgs.qmk.overridePythonAttrs`, passed to `toolboxLib.buildPackage { name = "qmk"; }`.
- `data.json`: version `1.2.0` (`_meta.default`); releases tracked at `https://github.com/qmk/qmk_cli/tags`.
- Output: the nixpkgs `qmk` CLI (`bin/qmk`), with `dos2unix` and `dfu-util` added to `propagatedBuildInputs`.
- Platforms: inherited from nixpkgs `qmk`.
- `patches/` (no code): `sigma-alt-home-1.2.0.patch`, vendored from fork `sigma/qmk_cli` branch `alt-home`.

## Invariants

- Each version entry needs `sha256` (hash of the PyPI sdist fetched with `fetchPypi`).
- `patches[]` is resolved through `toolboxLib.resolvePatches`; every `patches[].file` must exist on disk (enforced by `nix flake check`). `patches[].source` (owner/repo/branch/commit) is regeneration metadata only, consumed by the `/manage-patches` skill.
- Upstream's existing `patches` are kept; toolbox patches are appended.
- Python dependency versions come from the nixpkgs instance, not from a lockfile.

## Side Effects

- Build time only: fixed-output fetch of the PyPI sdist.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#qmk.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
