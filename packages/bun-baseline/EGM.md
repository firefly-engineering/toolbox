# bun-baseline

## Overview
Packages Bun's baseline builds (no AVX2 requirement) for x86 hosts, from the same `oven-sh/bun` releases as [bun](../bun/EGM.md).

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "bun-baseline"; binaries = [ "bun" ]; symlinks.bunx = "bun"; ... }`.
- Versions: `1.4.2` (`_meta.default`), `1.3.14`, `1.3.11`, `1.3.8`, `1.3.6`.
- Installs `$out/bin/bun` and `$out/bin/bunx -> bun`.
- Platforms table: x86_64-linux (`linux-x64-baseline`) and x86_64-darwin (`darwin-x64-baseline`) only. Of the systems the flake advertises, only x86_64-linux exposes it.

## Invariants
- Each version entry carries `<system>.sha256` for exactly the two x86 systems.
- The platforms table is the single declaration of support: it derives `meta.platforms`, so `availableVersions` filters the package out elsewhere instead of throwing.
- Versions track [bun](../bun/EGM.md); keep the two in step.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release zip.

## Verification
- Run: `nix build --no-link .#bun-baseline.default` (x86_64-linux only)
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
