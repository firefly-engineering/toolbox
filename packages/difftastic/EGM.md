# difftastic

## Overview
Packages [difftastic](https://difftastic.wilfred.me.uk), a structural diff tool, from upstream prebuilt release archives via `toolboxLib.buildPrebuiltBinary` (`lib/prebuilt-binary.nix`).

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "difftastic"; ... }`, passed to `toolboxLib.buildPackage`.
- URL: `https://github.com/Wilfred/difftastic/releases/download/<version>/difft-<triple>.tar.gz`, flat archive (`sourceRoot = "."`).
- Installs `$out/bin/difft` (`meta.mainProgram = "difft"`).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (Rust target triples as asset strings).
- `data.json`: versions `0.70.0` (default), `0.69.0`, `0.68.0`.
- No cross-package dependencies.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (`fetchurl` hash of the raw archive, no `--unpack`).
- Version keys and release tags have no `v` prefix.
- `patchelf` is left at its default (`true`), so Linux binaries go through `autoPatchelfHook`.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release archive. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#difftastic.default` (or `.#difftastic.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
