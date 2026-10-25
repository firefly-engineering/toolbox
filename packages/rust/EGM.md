# rust

## Overview

Packages the official Rust toolchain from `static.rust-lang.org` prebuilt dist tarballs, installed with upstream's `install.sh`. This is the Rust every source-built Rust package in the registry compiles with.

## Interface

- `default.nix`: custom `builders.default` (`stdenv.mkDerivation`) passed to `toolboxLib.buildPackage { name = "rust"; }`.
- `data.json`: versions `1.98.1` (`_meta.default`), `1.97.0`, `1.96.0`, `1.95.0`, `1.94.0`, `1.92.0`.
- Output: one prefix with components `rustc`, `cargo`, `rust-std-<host-triple>`, `clippy-preview`, `rustfmt-preview` (`bin/rustc`, `bin/cargo`, `bin/cargo-clippy`, `bin/clippy-driver`, `bin/rustfmt`, ...); installer manifests under `lib/rustlib/` are removed.
- `passthru.targetPlatforms = lib.platforms.all`, `passthru.badTargetPlatforms = [ ]`: lets it serve as `rustc` for `pkgs.makeRustPlatform`.
- `passthru.rustSrc`: a separate `rust-src-<version>` derivation with the std sources at `lib/rustlib/src/rust/library`, for `RUST_SRC_PATH`. It is passthru, so it does not change the toolchain derivation.
- Consumers: `toolbox.rust.versions.<rust>` from `toolboxLib.buildRustPackage` ([beads-rust](../beads-rust/EGM.md), [cargo-edit](../cargo-edit/EGM.md), [jj](../jj/EGM.md), [jj-hunk](../jj-hunk/EGM.md), [jrsonnet](../jrsonnet/EGM.md), [mdbook-admonish](../mdbook-admonish/EGM.md), [mdbook-footnote](../mdbook-footnote/EGM.md), [mdbook-graphviz](../mdbook-graphviz/EGM.md), [mdbook-mermaid](../mdbook-mermaid/EGM.md), [nil](../nil/EGM.md), [qmk_hid](../qmk_hid/EGM.md), [reindeer](../reindeer/EGM.md), [vitaly](../vitaly/EGM.md)), [delta](../delta/EGM.md)'s source fallback, [tuicr](../tuicr/EGM.md)'s `source` builder, and the [rust-toolchain](../rust-toolchain/EGM.md) toolchain.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`; any other system throws.

## Invariants

- Each version entry needs `<system>.sha256`: the raw-file hash (`fetchurl`, no `--unpack`) of `rust-<version>-<triple>.tar.xz`.
- `rustSrc.sha256` (required, platform-independent): the raw-file hash of `rust-src-<version>.tar.xz`. A version without it fails an `assert` at instantiation, so `nix flake check` rejects it.
- Host only: `rust-std` is installed for the host triple, no cross targets.
- Linux binaries are patched with `autoPatchelfHook` against `cc.cc.lib` (`libgcc_s.so.1`) and `zlib` (`libz.so.1`).

## Side Effects

- Build time only: fixed-output fetch of the dist tarball. Nothing is compiled.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#rust.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
