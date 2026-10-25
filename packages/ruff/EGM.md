# ruff

## Overview

Packages [ruff](https://github.com/astral-sh/ruff), Astral's Python linter and formatter, from upstream's prebuilt release tarballs.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "ruff"; }`.
- `data.json`: versions `0.17.0` (`_meta.default`), `0.16.6`, `0.16.1`, `0.15.20`, `0.15.6`, `0.15.5`.
- Output: `bin/ruff`.
- Asset URL: `https://github.com/astral-sh/ruff/releases/download/<version>/ruff-<rust-triple>.tar.gz` (tags have no `v` prefix), unpacked into `ruff-<rust-triple>/`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- Linux binaries go through `autoPatchelfHook` (helper default `patchelf = true`).

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#ruff.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
