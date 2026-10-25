# uv

## Overview

Packages [uv](https://github.com/astral-sh/uv), Astral's Python package and project manager, from upstream's prebuilt release tarballs.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "uv"; }`.
- `data.json`: versions `0.13.0` (`_meta.default`), `0.12.10`, `0.12.2`, `0.11.26`, `0.11.6`, `0.11.2`, `0.10.10`, `0.10.9`.
- Output: `bin/uv` and `bin/uvx`.
- Asset URL: `https://github.com/astral-sh/uv/releases/download/<version>/uv-<rust-triple>.tar.gz` (tags have no `v` prefix), unpacked into `uv-<rust-triple>/`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- Linux binaries go through `autoPatchelfHook` (helper default `patchelf = true`).

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#uv.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
