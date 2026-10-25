# entire

## Overview
Packages the [Entire CLI](https://entire.io), which captures AI agent sessions as a searchable record alongside Git commits, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "entire"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/entireio/cli/releases/download/v<version>/entire_<os>_<arch>.tar.gz`, flat archive (`sourceRoot = "."`). The platform strings carry the `.tar.gz` extension (`linux_amd64.tar.gz`, …), as in [gh](../gh/EGM.md) and [git-lfs](../git-lfs/EGM.md).
- Installs `$out/bin/entire` and `$out/bin/git-remote-entire` (a git remote helper); `postInstall` installs bash, fish and zsh completions from `completions/`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (also stated in `meta.platforms`).
- `data.json`: versions `0.11.4` (default), `0.10.6`, `0.10.5`, `0.8.42`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it.
- Release archives must keep shipping `completions/entire.{bash,fish,zsh}`, or `postInstall` fails.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#entire.default` (or `.#entire.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
