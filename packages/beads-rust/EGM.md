# beads-rust

## Overview
Packages beads_rust (`br`), a local-first issue tracker storing tasks in SQLite, built from the tagged source `Dicklesworthstone/beads_rust` with `toolboxLib.buildRustPackage`. Marked inactive (`_meta.inactive = true`).

## Interface
- `default.nix`: `builders.default = toolboxLib.buildRustPackage { pname = "beads-rust"; owner = "Dicklesworthstone"; repo = "beads_rust"; ... }`.
- Versions: `0.1.14` (`_meta.default`).
- Installs `$out/bin/br` (`meta.mainProgram`).
- Cross-package dep: `toolbox.rust.versions.${versionData.rust}` (Rust 1.92.0).
- Build inputs: pkg-config, openssl.

## Invariants
- Each version entry needs `sha256` (`--unpack` hash of `v<version>`), `cargoHash`, and `rust` (a version present in `packages/rust/data.json`).
- Tests are skipped (`doCheck = false`, set by `buildRustPackage`).

## Side Effects
- Build time only: fixed-output fetches of the source tarball and the vendored cargo dependencies.

## Verification
- Run: `nix build --no-link .#beads-rust.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
