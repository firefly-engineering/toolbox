# jrsonnet

## Overview

`jrsonnet` (Rust Jsonnet implementation) built from the `CertainLach/jrsonnet` tag via `toolboxLib.buildRustPackage`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.jrsonnet`: `versions` = 0.5.0-pre96-test; `default` = `0.5.0-pre96-test` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildRustPackage { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/jrsonnet` (`--bin jrsonnet`).
- Cross-package dependency: `toolbox.rust.versions.${versionData.rust}` (default version pins Rust `1.92.0`).

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball), `cargoHash` and `rust` (a version key of `packages/rust/data.json`).
- Dependencies are pinned by upstream's `Cargo.lock` via the fixed-output `cargoHash`.

## Side Effects

- Fixed-output fetch of the `CertainLach/jrsonnet` source tarball and crate dependencies at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#jrsonnet.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
