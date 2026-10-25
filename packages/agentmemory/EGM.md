# agentmemory

## Overview
Packages agentmemory (persistent memory CLI and MCP server for AI coding agents, TypeScript bundled with tsdown) from the tagged GitHub source `rohitg00/agentmemory` with a custom `pkgs.buildNpmPackage` builder. Upstream commits no lockfile, so this package uses the documented last resort: a vendored, version-namespaced lockfile.

## Interface
- `default.nix`: `toolboxLib.buildPackage { name = "agentmemory"; builders.default = ...; }` returning `{ versions; default; }` plus the `toolbox` stamp (`kind = "package"`).
- Versions: `0.9.27` (`_meta.default`).
- Installs `$out/bin/agentmemory` (`meta.mainProgram`); node_modules under `$out/lib/node_modules/@agentmemory/agentmemory`.
- `meta.platforms`: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- `package-lock-0.9.27.json`: vendored lockfile, copied to `package-lock.json` in `postPatch` (seen by both `fetchNpmDeps` and the build).
- No toolbox cross-package deps; pulls nixpkgs `claude-code` (unfree, allowed only for that package via a scoped `allowUnfreePredicate`). It comes from a second nixpkgs instance, `import pkgs.path { system; config.allowUnfreePredicate = ...; }`, so caller overlays and config do not reach it.

## Invariants
- Each `data.json` version entry needs `sha256` (`--unpack` hash of tag `v<version>`) and `npmDepsHash`.
- Every version must have a matching `package-lock-<version>.json` next to `default.nix`; never a shared lock name. It is generated with `npm install --package-lock-only --ignore-scripts` and installed with `npm ci`.
- `npmRebuildFlags = [ "--ignore-scripts" ]`: no install script may reach the network (e.g. sharp's libvips download).
- `postInstall` replaces the Claude Agent SDK's bundled `claude` binary with a shim (PATH `claude` first, else the pinned nixpkgs `claude-code`), and prunes non-host onnxruntime-node OS/arch dirs, Windows blobs, `onnxruntime-web` and transformers.js WASM/source maps.

## Side Effects
- Build time only: fixed-output fetches of the GitHub tarball and the npm dependency tree (`fetchNpmDeps`).
- Runtime (the packaged tool, not the build): the shim execs a `claude` binary for Claude-backed features.

## Verification
- Run: `nix build --no-link .#agentmemory.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
