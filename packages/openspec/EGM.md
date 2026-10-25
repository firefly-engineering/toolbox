# openspec

## Overview

OpenSpec CLI (pnpm/TypeScript) built from the `Fission-AI/OpenSpec` tag with `buildNpmPackage`, dependencies pinned by upstream's `pnpm-lock.yaml` through `fetchPnpmDeps`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.openspec`: `versions` = 1.6.0; `default` = `1.6.0`.
- Builder: custom `builders.default` using `pkgs.buildNpmPackage` with `npmDeps = null`, `pnpmDeps = pkgs.fetchPnpmDeps { fetcherVersion = 4; ... }`, `npmConfigHook = pkgs.pnpmConfigHook`, `dontNpmPrune = true`.
- Installs `bin/openspec` (`mainProgram`).
- Cross-package dependency: `toolbox.pnpm.versions.${versionData.pnpm}` (default pins pnpm 11.17.0), not nixpkgs' pnpm.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin. On x86_64-darwin its pnpm dependency throws (pnpm has no binary there); this is unreachable because the flake does not advertise x86_64-darwin.

## Invariants

- Each version entry carries `sha256` (`--unpack` hash of the tag), `pnpm` (a version key of `packages/pnpm/data.json`) and `pnpmDeps` (the `fetchPnpmDeps` output hash).
- Built from the source tag, never the npm tarball (which ships no lockfile); no dependency is resolved at build time and a stale lock fails the build.
- The pinned pnpm must read the lockfile's `lockfileVersion` (9.0); upstream's `packageManager` pnpm 9 is not used.

## Side Effects

- Fixed-output fetch of the source tarball and the pnpm dependency store (`fetchPnpmDeps` FOD) at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#openspec.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
