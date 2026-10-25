# gh-aw

## Overview
Packages the [`gh-aw`](https://github.com/github/gh-aw) GitHub CLI extension as a single prebuilt binary via `toolboxLib.buildPrebuiltBinary`. Note: `meta.description` reads "GitHub CLI extension for activity watching"; upstream describes gh-aw as GitHub Agentic Workflows.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "gh-aw"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/github/gh-aw/releases/download/v<version>/<os>-<arch>` (bare binary, `sourceRoot = null`, no unpack).
- Installs `$out/bin/gh-aw` (`meta.mainProgram = "gh-aw"`).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
- `data.json`: versions `0.88.7` (default), `0.88.2`, `0.81.6`, `0.74.0`, `0.68.3`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-file `fetchurl` hash).
- Version keys have no `v` prefix; the URL adds it.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release binary. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#gh-aw.default` (or `.#gh-aw.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
