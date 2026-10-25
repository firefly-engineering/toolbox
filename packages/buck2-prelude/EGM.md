# buck2-prelude

## Overview
Pins the Buck2 prelude (`facebook/buck2-prelude`) at specific commits. The derivation is the fetched source tree itself; there is no build step.

## Interface
- `default.nix`: custom builder `builders.default = version: versionData: pkgs.fetchFromGitHub { rev = versionData.rev; hash = versionData.sha256; ... }`.
- Versions (named after buck2 release dates, but not every buck2 release has one: buck2 `2026-04-15`, pinned by buck2-toolchain `3`, has no prelude entry): `2026-09-15` (`_meta.default`), `2026-07-01`, `2026-03-15`, `2025-12-01`.
- `passthru.version` and `passthru.preludeRev` (the pinned commit) for downstream consumers (turnkey).
- No binaries; no cross-package deps.

## Invariants
- Each version entry needs `rev` (commit SHA) and `sha256` (`--unpack` hash of that commit).
- `_meta.releases` points at the repository, not a releases page: the prelude has no releases.

## Side Effects
- Build time only: fixed-output fetch of the GitHub tarball.

## Verification
- Run: `nix build --no-link .#buck2-prelude.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
