# gh

## Overview
Packages [GitHub CLI](https://cli.github.com) (`gh`) from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "gh"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/cli/cli/releases/download/v<version>/gh_<version>_<platform>`; the platform string carries the extension (`linux_*.tar.gz`, `macOS_*.zip`), which `buildPrebuiltBinary` uses to unzip automatically.
- `sourceRoot` is a function stripping `.tar.gz`/`.zip` from the platform string: `gh_<version>_<os>_<arch>`.
- Installs `bin/gh` as `$out/bin/gh` (`meta.mainProgram = "gh"`).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `2.101.0` (default), `2.100.0`, `2.96.0`, `2.95.0`, `2.92.0`, `2.91.0`, `2.90.0`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it.
- The extension-in-platform-string idiom is shared with [git-lfs](../git-lfs/EGM.md).

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#gh.default` (or `.#gh.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
