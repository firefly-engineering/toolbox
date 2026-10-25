# solc

## Overview

Packages [solc](https://soliditylang.org/), the Solidity compiler, from upstream's static release binaries.

## Interface

- `default.nix`: `toolboxLib.buildPrebuiltBinary` builder passed to `toolboxLib.buildPackage { name = "solc"; }`.
- `data.json`: versions `0.8.35` (`_meta.default`), `0.8.34`.
- Output: `bin/solc`.
- Asset URL: `https://github.com/ethereum/solidity/releases/download/v<version>/<asset>` where `<asset>` is `solc-static-linux`, `solc-static-linux-arm` or `solc-macos` (the same macOS asset serves both Darwin systems); single uncompressed binary.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (from the `platforms` table; any other system throws and is filtered out by `availableVersions`).
- Consumed as a component by [solidity-toolchain](../solidity-toolchain/EGM.md).

## Invariants

- Each version entry needs `<system>.sha256` for all four systems: the raw-file hash of the release asset (`fetchurl`, so prefetch without `--unpack`).
- Both Darwin entries hash the same `solc-macos` asset, so their `sha256` values must be identical.
- `patchelf = false`: the Linux binaries are static.

## Side Effects

- Build time only: fixed-output fetch of the release asset. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#solc.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
