# mdbook

## Overview

`mdbook` installed from upstream's prebuilt release tarballs via `toolboxLib.buildPrebuiltBinary`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.mdbook`: `versions` = 0.4.52, 0.5.2, 0.5.3; `default` = `0.5.3` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildPrebuiltBinary { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/mdbook`.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Asset URL: `https://github.com/rust-lang/mdBook/releases/download/v${version}/mdbook-v${version}-${platform}.tar.gz`.

## Invariants

- `data.json` nests one `{ sha256 }` per system under each version; the hash is the raw `fetchurl` hash of the release asset (no `--unpack`).
- Evaluation throws on a system missing from the `platforms` table. `meta.platforms` is set by hand in `default.nix` and overrides the value derived from that table, so the two lists can drift apart; `availableVersions` filters on the hand-set list.
- x86_64-linux uses the `-gnu` asset, aarch64-linux the `-musl` asset; tarball unpacked flat.

## Side Effects

- Fixed-output fetch of the per-system release asset at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#mdbook.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
