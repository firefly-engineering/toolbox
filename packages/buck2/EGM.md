# buck2

## Overview
Packages Meta's Buck2 build system as a prebuilt, zstd-compressed binary from `facebook/buck2` GitHub releases, and publishes the source commit each release tag points at.

## Interface
- `default.nix`: `builders.default` wraps `toolboxLib.buildPrebuiltBinary { pname = "buck2"; ... }` with `overrideAttrs` adding `passthru.rev`.
- Versions (date-named release tags): `2026-09-15` (`_meta.default`), `2026-07-01`, `2026-04-15`, `2026-03-15`, `2025-12-01`.
- Installs `$out/bin/buck2` (decompressed from `buck2-<triple>.zst`). On Linux it goes through `autoPatchelfHook` (default `patchelf = true`).
- Platforms table: x86_64/aarch64 Linux (`*-unknown-linux-gnu`), x86_64/aarch64 Darwin (`*-apple-darwin`).
- `passthru.rev`: buck2 commit of the tag; consumed by turnkey to check against its pinned release.
- Used by [buck2-toolchain](../buck2-toolchain/EGM.md).

## Invariants
- Each version entry needs `rev` (from `gh api repos/facebook/buck2/commits/<tag> --jq .sha`) and `<system>.sha256` for all four systems.
- Known defect: a missing `rev` throws only when `passthru.rev` is read, and `nix flake check` never reads it, so an entry without `rev` passes the gate.
- `passthru.rev` is passthru only: it does not change the derivation.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release asset.

## Verification
- Run: `nix build --no-link .#buck2.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
