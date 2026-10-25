# ty

## Overview

Packages [ty](https://github.com/astral-sh/ty), Astral's Python type checker, from upstream's prebuilt release tarballs.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "ty"; }`.
- `data.json`: versions `0.0.86` (`_meta.default`), `0.0.78`, `0.0.69`, `0.0.58`, `0.0.56`, `0.0.35`.
- Output: `bin/ty`.
- Asset URL: `https://github.com/astral-sh/ty/releases/download/<version>/ty-<rust-triple>.tar.gz` (tags have no `v` prefix), unpacked into `ty-<rust-triple>/`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- Linux binaries go through `autoPatchelfHook` (helper default `patchelf = true`).

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#ty.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
