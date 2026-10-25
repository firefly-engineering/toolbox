# cargo-edit

## Overview
Packages cargo-edit (Cargo subcommands such as `cargo add`, `cargo rm` and `cargo upgrade`), built from the tagged source `killercup/cargo-edit` with `toolboxLib.buildRustPackage`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildRustPackage { pname = "cargo-edit"; owner = "killercup"; repo = "cargo-edit"; ... }`.
- Versions: `0.13.9` (`_meta.default`).
- Installs the crate's cargo subcommand binaries into `$out/bin` (`meta.mainProgram = "cargo-add"`).
- Cross-package dep: `toolbox.rust.versions.${versionData.rust}` (Rust 1.92.0).
- Build inputs: pkg-config, openssl.

## Invariants
- Each version entry needs `sha256` (`--unpack` hash of `v<version>`), `cargoHash` and `rust`.
- Tests are skipped (`doCheck = false`, set by `buildRustPackage`).

## Side Effects
- Build time only: fixed-output fetches of the source tarball and the vendored cargo dependencies.

## Verification
- Run: `nix build --no-link .#cargo-edit.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
