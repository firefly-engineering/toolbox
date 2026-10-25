# hunk

## Overview
Packages [hunk](https://github.com/modem-dev/hunk), a review-first terminal diff viewer for agentic coders, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary`. The archive also ships agent skills, which are kept in the output.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "hunk"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/modem-dev/hunk/releases/download/v<version>/hunkdiff-<os>-<arch>.tar.gz`; `sourceRoot = "hunkdiff-<os>-<arch>"`.
- Installs `$out/bin/hunk` (`meta.mainProgram = "hunk"`); `postInstall` creates the relative symlink `$out/bin/hunkdiff -> hunk` (not via the `symlinks` parameter), copies `skills/` to `$out/skills` and `metadata.json` to `$out/metadata.json`.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (asset strings use `x64`/`arm64`).
- `data.json`: versions `0.23.0` (default), `0.22.0`, `0.21.1`, `0.17.7`, `0.17.0`, `0.16.0`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-archive `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it.
- Release archives must keep `skills/` and `metadata.json` at the archive root, or `postInstall` fails.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#hunk.default` (or `.#hunk.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
