# git-lfs

## Overview
Packages [Git LFS](https://git-lfs.com) from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "git-lfs"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/git-lfs/git-lfs/releases/download/v<version>/git-lfs-<os>-<arch>-v<version>.<ext>`; the platform string carries the extension (Linux `.tar.gz`, Darwin `.zip`), split back out by the local `extOf` helper (same idiom as [gh](../gh/EGM.md)).
- `sourceRoot = "git-lfs-<version>"`.
- Installs `$out/bin/git-lfs` (`meta.mainProgram = "git-lfs"`); `postInstall` installs man pages from `man/man1`, `man/man5`, `man/man7`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `3.8.0` (default), `3.7.1`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it in both tag and file name.
- Archives must keep the `git-lfs-<version>/` top directory and the three man sections, or unpack/`postInstall` fails.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#git-lfs.default` (or `.#git-lfs.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
