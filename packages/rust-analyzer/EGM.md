# rust-analyzer

## Overview

Packages [rust-analyzer](https://rust-analyzer.github.io/), the Rust language server, from upstream's prebuilt gzip-compressed binaries.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "rust-analyzer"; }`.
- `data.json`: versions are upstream date tags: `2026-07-06` (`_meta.default`), `2026-06-22`, `2026-04-27`, `2026-03-23`, `2026-03-09`.
- Output: `bin/rust-analyzer`.
- Asset URL: `https://github.com/rust-lang/rust-analyzer/releases/download/<version>/rust-analyzer-<rust-triple>.gz`; single binary, the `.gz` transport compression is auto-detected and decompressed by the helper.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).
- Consumed as a component by [rust-toolchain](../rust-toolchain/EGM.md).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- Version keys must match the upstream date tag exactly (`YYYY-MM-DD`).
- Linux binaries go through `autoPatchelfHook` (helper default `patchelf = true`).

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#rust-analyzer.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
