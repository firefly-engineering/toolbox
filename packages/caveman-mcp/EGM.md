# caveman-mcp

## Overview
Packages Caveman's MCP server (stdio): `caveman_retrieve` plus compress, stats and TOON tools over the shared recovery store. It is the agent-side recovery path that [caveman-proxy](../caveman-proxy/EGM.md) needs before it compresses traffic. Prebuilt binary from `JuliusBrussee/caveman` `bin-v<version>` releases.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "caveman-mcp"; binaries = [ "caveman-mcp" ]; ... }`.
- Versions: `2.1.0` (`_meta.default`), `2.0.2`.
- Installs `$out/bin/caveman-mcp` (`meta.mainProgram`); single uncompressed binary `caveman-mcp_<os>_<arch>`.
- Platforms table: linux/darwin x amd64/arm64.
- Registered in Claude Code as server `caveman` (tools `mcp__caveman__*`).

## Invariants
- Each version entry carries `<system>.sha256` for all four systems.
- Pinned to the same `bin-v<version>` release as caveman-proxy: both read and write the same `ccr.db`, so bump them together.
- `patchelf = false`: static Go binary.

## Side Effects
- Build time only: fixed-output `fetchurl` of the release asset.
- Runtime (the packaged tool, not the build): reads and writes `$CAVEMAN_CCR_DB`, else `$CAVEMAN_HOME/ccr.db` (default `~/.caveman/ccr.db`).

## Verification
- Run: `nix build --no-link .#caveman-mcp.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
