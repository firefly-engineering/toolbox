# golangci-lint

## Overview
Packages [golangci-lint](https://golangci-lint.run/), the Go linters runner, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "golangci-lint"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/golangci/golangci-lint/releases/download/v<version>/golangci-lint-<version>-<os>-<arch>.tar.gz`; `sourceRoot = "golangci-lint-<version>-<os>-<arch>"`.
- Installs `$out/bin/golangci-lint`. No `meta.mainProgram`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `2.15.0` (default), `2.12.2`, `2.11.3`.
- No cross-package dependencies. Consumed by [go-toolchain](../go-toolchain/EGM.md).

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it to the tag.
- The prebuilt binary embeds its own Go; it does not use the toolbox `go`.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#golangci-lint.default` (or `.#golangci-lint.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
