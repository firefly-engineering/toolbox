# typescript

## Overview

Packages the TypeScript compiler from the npm registry. Three builder variants cover the JavaScript compiler (6.x), the TypeScript 7 native-preview channel (`tsgo`), and released TypeScript 7 (native Go `tsc`).

## Interface

- `default.nix`: builders passed to `toolboxLib.buildPackage { name = "typescript"; }`, all custom `stdenv.mkDerivation`:
  - `default` (6.x): fetches `typescript-<version>.tgz`, installs it under `lib/node_modules/typescript`, and writes `bin/tsc` and `bin/tsserver` shell wrappers running toolbox node.
  - `tsgo`: fetches `@typescript/native-preview-<platform>`; installs `lib/tsgo/` and `bin/tsgo` (symlink).
  - `ts7`: fetches `@typescript/typescript-<platform>`; installs `lib/typescript/` and `bin/tsc` (symlink). No `tsserver`: the language server is `tsc --lsp`.
- `data.json`: `7.0.2` (`_meta.default`, `builder = "ts7"`), `6.0.3` (`default`), `7.0.0-dev.20260707.2` (`builder = "tsgo"`).
- Cross-package deps: `default` uses `toolbox.nodejs.versions.${toolbox.nodejs.default}` ([nodejs](../nodejs/EGM.md)). Consumed by [typescript-toolchain](../typescript-toolchain/EGM.md).
- Platforms: `tsgo`/`ts7` on `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin` (others throw); `default` declares none (pure JS).

## Invariants

- `default` entries need `sha256` (raw `fetchurl` hash of the npm tarball); `tsgo`/`ts7` entries need `<system>.sha256` for all four systems.
- `default` follows toolbox nodejs's *default* version, not a per-version pin, so its derivation changes when `nodejs`'s `_meta.default` moves.
- `tsgo`/`ts7` keep the whole `lib/` tree together: the binary loads the `lib.*.d.ts` standard library relative to its real path, so `bin/` must be a symlink into `lib/`, not a copy.
- Native binaries are statically linked; no `autoPatchelfHook`.

## Side Effects

- Build time only: fixed-output fetch of the npm tarball. Nothing is compiled; no npm dependency resolution happens (the tarballs have no runtime dependencies).

## Verification

Run from the repository root:

- Run: `nix build --no-link .#typescript.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
