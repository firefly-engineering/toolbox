# pnpm

## Overview

pnpm installed from its standalone per-platform release tarball; a custom `mkDerivation` using `toolboxLib.unpackFlat`, made a drop-in for nixpkgs' pnpm build helpers.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.pnpm`: `versions` = 11.17.0, 12.3.4; `default` = `12.3.4`.
- Asset URL: `https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${platform}.tar.gz`.
- Installs `libexec/pnpm/{pnpm,dist/}` and symlinks `bin/pnpm` to the launcher.
- `passthru.nodejs-slim = pkgs.nodejs-slim`, which nixpkgs' `fetchPnpmDeps` reads.
- Platforms: x86_64-linux, aarch64-linux, aarch64-darwin (no x86_64-darwin).
- Consumed by [openspec](../openspec/EGM.md), [js-toolchain](../js-toolchain/EGM.md) and [typescript-toolchain](../typescript-toolchain/EGM.md) (versions 4 and 5).

## Invariants

- Each version nests `{ sha256 }` per system (raw `fetchurl` hash).
- The launcher loads `dist/pnpm.mjs` relative to its real path, so the binary and `dist/` must stay together.
- Evaluation throws on x86_64-darwin or a version lacking that system's entry.

## Side Effects

- Fixed-output fetch of the per-system release tarball at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#pnpm.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
