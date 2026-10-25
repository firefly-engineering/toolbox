# just

## Overview

`just` command runner installed from upstream release tarballs via `toolboxLib.buildPrebuiltBinary`, with man page and completions.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.just`: `versions` = 1.51.0, 1.54.0, 1.56.0, 1.58.0; `default` = `1.58.0` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildPrebuiltBinary { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/just`, man page `just.1`, bash/fish/zsh completions.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Asset URL: `https://github.com/casey/just/releases/download/${version}/just-${version}-${platform}.tar.gz`.

## Invariants

- `data.json` nests one `{ sha256 }` per system under each version; the hash is the raw `fetchurl` hash of the release asset (no `--unpack`).
- Evaluation throws on a system missing from the `platforms` table. `meta.platforms` is set by hand in `default.nix` and overrides the value derived from that table, so the two lists can drift apart; `availableVersions` filters on the hand-set list.
- Linux assets are the `*-unknown-linux-musl` builds; tarball is unpacked flat (`sourceRoot = "."`).

## Side Effects

- Fixed-output fetch of the per-system release asset at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#just.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
