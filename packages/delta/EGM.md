# delta

## Overview
Packages [delta](https://github.com/dandavison/delta), a syntax-highlighting pager for git, diff and grep output. A hybrid package: prebuilt release tarballs where upstream ships them for the host system, a Rust source build otherwise. Custom builder (not `buildPrebuiltBinary`, because it dispatches per system between two build strategies).

## Interface
- `default.nix`: `{ pkgs, lib, toolbox, toolboxLib }` -> `toolboxLib.buildPackage { name = "delta"; ... }`, one builder `default`.
  - If `versionData` has an entry for the host system: `mkPrebuilt` (`stdenv.mkDerivation`, `fetchurl` of `delta-<version>-<triple>.tar.gz`; on Linux `autoPatchelfHook` with `cc.cc.lib` and `zlib`).
  - Otherwise: `mkFromSource` (`makeRustPlatform` + `buildRustPackage` from `fetchFromGitHub` at `rev = version`, `doCheck = false`).
- Installs `$out/bin/delta` (`meta.mainProgram = "delta"`).
- `data.json`: versions `0.20.1` (default), `0.19.2`; `_meta.releases` = GitHub releases.
- Prebuilt systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`. Any other system, `x86_64-darwin` included, has no prebuilt entry and builds from source. Neither builder sets `meta.platforms`.
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (0.20.1 -> rust 1.98.1, 0.19.2 -> rust 1.94.0), source path only.

## Invariants
- Version keys have no `v` prefix; the release tag and source `rev` are the bare version.
- Each version entry carries `<system>.sha256` per prebuilt system, plus `srcHash`, `cargoHash` and `rust` for the source fallback. The dispatch is on presence of `versionData.${system}`, so adding a system key switches that system to the prebuilt path.
- `targetTriple` must have an entry for every system key present in `data.json`, or evaluation fails on that system.
- `versionData.rust` must name an existing [rust](../rust/EGM.md) version.

## Side Effects
- Build time only: fixed-output fetches of the GitHub release tarball or the tagged source and its cargo dependencies (pinned by `sha256` / `srcHash` / `cargoHash`). No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#delta.default` (or `.#delta.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
