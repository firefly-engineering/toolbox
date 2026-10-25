# treefmt

## Overview

Packages [treefmt](https://github.com/numtide/treefmt), the multi-formatter runner, from upstream's prebuilt release tarballs.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "treefmt"; }`.
- `data.json`: version `2.5.0` (`_meta.default`).
- Output: `bin/treefmt`.
- Asset URL: `https://github.com/numtide/treefmt/releases/download/v<version>/treefmt_<version>_<os>_<arch>.tar.gz`; a flat archive (`sourceRoot = "."`).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- `patchelf = false`: statically linked Go binary.

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#treefmt.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
