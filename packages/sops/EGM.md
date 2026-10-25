# sops

## Overview

Packages [sops](https://getsops.io), the secrets-file editor, from upstream's prebuilt release binaries.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "sops"; }`.
- `data.json`: version `3.13.3` (`_meta.default`).
- Output: `bin/sops`.
- Asset URL: `https://github.com/getsops/sops/releases/download/v<version>/sops-v<version>.<os>.<arch>` (e.g. `linux.amd64`, `darwin.arm64`); single uncompressed binary.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- `patchelf = false`: statically linked Go binary.
- `meta` declares no `platforms` of its own; they come from the helper's `platforms` table.

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#sops.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
