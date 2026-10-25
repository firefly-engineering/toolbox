# caveman-proxy

## Overview
Packages Caveman's standalone gateway: a base-URL-swap reverse proxy for LLM traffic (record mode by default, `mode: compress` in `caveman.yaml` compresses in-process). Prebuilt binary from `JuliusBrussee/caveman` `bin-v<version>` releases. The Node `caveman` CLI that wraps it is not packaged.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "caveman-proxy"; binaries = [ "caveman-proxy" ]; ... }`.
- Versions: `2.1.0` (`_meta.default`), `2.0.2`.
- Installs `$out/bin/caveman-proxy` (`meta.mainProgram`); single binary `caveman-proxy_<os>_<arch>`.
- Platforms table: linux/darwin x amd64/arm64.
- Siblings: [caveman-mcp](../caveman-mcp/EGM.md) (shared `ccr.db`), [caveman-skills](../caveman-skills/EGM.md) (skills, separate `v<version>` tags).

## Invariants
- Each version entry carries `<system>.sha256` for all four systems.
- Same `bin-v<version>` release as caveman-mcp; bump the two together.
- `patchelf = false`: static Go binary.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release asset.
- Runtime (the packaged tool, not the build): listens locally (e.g. `127.0.0.1:8787`) and forwards LLM API traffic upstream.

## Verification
- Run: `nix build --no-link .#caveman-proxy.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
