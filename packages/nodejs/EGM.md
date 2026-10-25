# nodejs

## Overview

Node.js installed from the official nodejs.org per-platform binary tarball; a custom `mkDerivation` (whole toolchain tree, so not `buildPrebuiltBinary`).
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.nodejs`: `versions` = 24.14.0, 24.18.0, 24.20.0, 25.9.0, 26.1.0; `default` = `24.20.0`.
- Asset URL: `https://nodejs.org/dist/v${version}/node-v${version}-${platformKey}.tar.xz`.
- Installs the tarball's `bin`, `lib`, `include`, `share` into `$out` (`bin/node`, `bin/npm`, `bin/npx`, ...).
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.

## Invariants

- Each version nests `{ sha256 }` per system (raw `fetchurl` hash, no `--unpack`).
- Evaluation throws on an unsupported system or a version lacking that system's entry.
- Linux binaries are patched with `autoPatchelfHook` against `stdenv.cc.cc.lib`; `dontStrip`.

## Side Effects

- Fixed-output fetch of the nodejs.org tarball at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#nodejs.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
