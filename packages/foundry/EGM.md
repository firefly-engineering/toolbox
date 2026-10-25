# foundry

## Overview
Packages [Foundry](https://getfoundry.sh/), the Ethereum development toolkit, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "foundry"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/foundry-rs/foundry/releases/download/<version>/foundry_<version>_<os>_<arch>.tar.gz`, flat archive (`sourceRoot = "."`).
- Installs `$out/bin/forge`, `cast`, `anvil`, `chisel`. No `meta.mainProgram`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `v1.7.1` (default), `v1.5.1`.
- No cross-package dependencies. Consumed as a component by [solidity-toolchain](../solidity-toolchain/EGM.md).

## Invariants
- Version keys carry the `v` prefix (`v1.7.1`), matching upstream tags; the URL interpolates the key verbatim in both the tag and the file name.
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#foundry.default` (or `.#foundry.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
