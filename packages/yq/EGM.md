# yq

## Overview

Packages [yq](https://mikefarah.gitbook.io/yq/) (mikefarah), the YAML/JSON/XML/CSV/TOML processor, from upstream's prebuilt release binaries.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "yq"; }`.
- `data.json`: version `4.53.3` (`_meta.default`).
- Output: `bin/yq`.
- Asset URL: `https://github.com/mikefarah/yq/releases/download/v<version>/yq_<os>_<arch>`; single uncompressed binary.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- `patchelf = false`: statically linked Go binary.

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#yq.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
