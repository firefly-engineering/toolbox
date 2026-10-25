# biome

## Overview
Packages Biome (formatter and linter for web languages) as a prebuilt single binary from `biomejs/biome` GitHub releases.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "biome"; binaries = [ "biome" ]; ... }`.
- Versions: `2.5.2` (`_meta.default`), `2.4.7`, `2.4.6`.
- Installs `$out/bin/biome`.
- Platforms table: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin (assets `biome-<os>-<arch>` under tag `@biomejs/biome@<version>`).
- No cross-package deps.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-file hash).
- Linux binaries go through `autoPatchelfHook` (default `patchelf = true`).

## Side Effects
- Build time only: fixed-output `fetchurl` of the release asset.

## Verification
- Run: `nix build --no-link .#biome.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
