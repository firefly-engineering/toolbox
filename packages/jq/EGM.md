# jq

## Overview

`jq` JSON processor installed from upstream's static per-platform release binary via `toolboxLib.buildPrebuiltBinary`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.jq`: `versions` = 1.8.1, 1.8.2; `default` = `1.8.2` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildPrebuiltBinary { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/jq`.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Asset URL: `https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${platform}`.

## Invariants

- `data.json` nests one `{ sha256 }` per system under each version; the hash is the raw `fetchurl` hash of the release asset (no `--unpack`).
- Evaluation throws on a system missing from the `platforms` table. `meta.platforms` is set by hand in `default.nix` and overrides the value derived from that table, so the two lists can drift apart; `availableVersions` filters on the hand-set list.
- Single static binary: no unpack, `patchelf = false`.

## Side Effects

- Fixed-output fetch of the per-system release asset at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#jq.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
