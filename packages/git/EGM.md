# git

## Overview
Builds [Git](https://git-scm.com) from the kernel.org release tarball with a custom `stdenv.mkDerivation` builder.

## Interface
- `default.nix`: `builders.default` = `pkgs.stdenv.mkDerivation` with `fetchurl` of `https://mirrors.edge.kernel.org/pub/software/scm/git/git-<version>.tar.xz`, passed to `toolboxLib.buildPackage`.
- Build inputs: `curl`, `openssl`, `zlib`, `pcre2`, `expat` (plus `apple-sdk_15` on Darwin); native `pkg-config`, `gettext`.
- `makeFlags`: `prefix=$(out)`, `NO_TCLTK=1` (no gitk/git-gui), `INSTALL_SYMLINKS=1`, `NO_RUST=1`. `doCheck = false`.
- Installs the standard git tree under `$out` (`meta.mainProgram = "git"`).
- Platforms: wherever nixpkgs `stdenv` builds it (no explicit `meta.platforms`).
- `data.json`: versions `2.55.0` (default), `2.54.0`, `2.53.0`; `_meta.releases` = `github.com/git/git/tags`.
- No cross-package dependencies (dependencies come from nixpkgs).

## Invariants
- Each version entry carries only `sha256`, the raw-tarball `fetchurl` hash (no `--unpack`).
- `NO_RUST=1` keeps the optional Rust libgitcore out of 2.x builds; it is a no-op before 2.55 and will stop being an option at Git 3.0, which needs a new builder variant.

## Side Effects
- Build time only: fixed-output `fetchurl` of the source tarball. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#git.default` (or `.#git.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
