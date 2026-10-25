# aperture-cli

## Overview
Packages Tailscale's `aperture` launcher for agentic coding tools through Aperture, as a prebuilt per-platform binary from `tailscale/aperture-cli` GitHub releases.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "aperture-cli"; ... }` passed to `toolboxLib.buildPackage`.
- Versions: `0.0.13` (`_meta.default`).
- Installs `$out/bin/aperture` (`meta.mainProgram`).
- Platforms table: x86_64-linux (`linux_amd64`), aarch64-linux (`linux_arm64`), x86_64-darwin (`darwin_amd64`), aarch64-darwin (`darwin_arm64`).
- Assets: Linux `aperture-cli_<platform>.tar.gz` (flat, binary `aperture`); macOS `aperture_v<version>_<platform>.zip` (binary `release/aperture_<platform>`, renamed to `aperture`). `sourceRoot = "."`.
- No cross-package deps.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw-file `fetchurl` hash, no `--unpack`).
- `patchelf = false`: static Go binary.
- The Linux/macOS asset layout split dates from 0.0.13; a future layout change gets a new builder variant, not an edit to `default`.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release asset.

## Verification
- Run: `nix build --no-link .#aperture-cli.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
