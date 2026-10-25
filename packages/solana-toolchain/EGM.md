# solana-toolchain

## Overview

Solana on-chain toolchain: nixpkgs `solana-cli`, `anchor` and `rustup`, plus a host-independent `cargo-build-sbf` that builds against a pinned, offline SBF SDK (nixpkgs' SDK scaffolding with toolbox `platform-tools` mounted in). Consumers put it on a dev shell with no `SBF_SDK_PATH`/`RUSTUP_HOME`/`--tools-version` setup and no platform-tools download; `anchor build` works because it finds the wrapped `cargo-build-sbf` on `PATH`.

It is a hand-written `symlinkJoin`, not `buildToolchain`: the wrapped `cargo-build-sbf` is logic `buildToolchain` does not model. It is the one registry entry that hand-builds its `{ versions; default; toolbox; }` return (see `docs/adr/0003`).

## Interface

- `default.nix`: returns `{ versions = { <default> = toolchain; }; default; toolbox = toolboxLib.mkStamp { kind = "toolchain"; meta; components = data.versions; }; }`, reading `data.json` with `toolboxLib.readData`.
- `data.json`: version `v1.54` (`_meta.default`) pinning `platform-tools` `v1.54`; releases tracked at `https://github.com/anza-xyz/platform-tools/releases`.
- `cargo-build-sbf.sh`: wrapper template installed as `$out/bin/cargo-build-sbf` via `substitute` (`@sbfSdk@`, `@rustup@`, `@cargoBuildSbf@`), replacing solana-cli's raw binary.
- Output `bin/`: everything from `solana-cli` (`solana`, `solana-keygen`, `solana-test-validator`, `agave-*`, ...), `anchor`, `rustup`, and the wrapped `cargo-build-sbf`.
- `passthru.sbfSdk` (the assembled SDK, `solana-sbf-sdk-<version>`) and `passthru.platformTools`.
- Cross-package deps: `toolbox.platform-tools.versions.<platform-tools>` ([platform-tools](../platform-tools/EGM.md)); `solana-cli`, `anchor`, `rustup` come from nixpkgs, unpinned by toolbox.
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Invariants

- Only `_meta.default` is built: `versions` holds exactly one entry, so other keys in `data.json` are ignored by the derivation (but still appear in the stamp's `components`).
- The hand-built return must carry the `toolbox` stamp; `checkRegistry` fails the flake check without it.
- The wrapper runs `cargo-build-sbf --skip-tools-install`, so it never downloads platform-tools; `SBF_SDK_PATH` and `RUSTUP_HOME` are honoured if already set, else default to the pinned SDK and an isolated rustup home.
- The docs generator reads the `.#manifest` built from stamps, not `data.json`: the stamp is what makes this entry documented.

## Side Effects

- Build time: none beyond its inputs (the SDK is copied together with `runCommand`).
- Run time (`cargo-build-sbf`): creates `$RUSTUP_HOME` (default `${XDG_CACHE_HOME:-$HOME/.cache}/solana-toolchain/rustup`), runs `rustup toolchain link sbf-platform-tools` and `rustup default sbf-platform-tools` there (errors ignored), and puts the pinned `rustup` first on `PATH`. The host's own rustup state is not touched unless the caller set `RUSTUP_HOME` to it.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#solana-toolchain.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
