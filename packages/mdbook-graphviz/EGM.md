# mdbook-graphviz

## Overview

`mdbook-graphviz` mdBook preprocessor built from source via `toolboxLib.buildRustPackage` and wrapped to find Graphviz.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.mdbook-graphviz`: `versions` = 0.2.1; `default` = `0.2.1` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildRustPackage { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/mdbook-graphviz` (`--bin mdbook-graphviz`), wrapped with nixpkgs `graphviz` prefixed on `PATH`.
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (default version pins Rust `1.92.0`).

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball), `cargoHash` and `rust` (a version key of `packages/rust/data.json`).
- Dependencies are pinned by upstream's `Cargo.lock` via the fixed-output `cargoHash`.
- `graphviz` comes from the pinned nixpkgs, not toolbox.

## Side Effects

- Fixed-output fetch of the `dylanowen/mdbook-graphviz` source tarball and crate dependencies at build time only; evaluation is offline.
- At runtime the wrapped binary executes `dot` from the wrapped `graphviz`.

## Verification

Run from the repository root:

```bash
nix build --no-link .#mdbook-graphviz.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
