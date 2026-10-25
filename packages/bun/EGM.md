# bun

## Overview
Packages the Bun JavaScript runtime, bundler, test runner and package manager as a prebuilt binary from `oven-sh/bun` GitHub releases.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildPrebuiltBinary { pname = "bun"; binaries = [ "bun" ]; symlinks = { bunx = "bun"; }; ... }`.
- Versions: `1.4.2` (`_meta.default`), `1.3.14`, `1.3.11`, `1.3.8`, `1.3.6`.
- Installs `$out/bin/bun` and `$out/bin/bunx -> bun`.
- Platforms table: x86_64-linux (`linux-x64`), aarch64-linux (`linux-aarch64`), x86_64-darwin (`darwin-x64`), aarch64-darwin (`darwin-aarch64`); asset `bun-<platform>.zip` under tag `bun-v<version>`, unpacked into `bun-<platform>/`.
- Sibling: [bun-baseline](../bun-baseline/EGM.md) packages the non-AVX2 x86 builds of the same releases.

## Invariants
- Each version entry carries `<system>.sha256` for all four systems (raw zip hash).
- Linux binary goes through `autoPatchelfHook` (default `patchelf = true`).

## Side Effects
- Build time only: fixed-output `fetchurl` of the release zip.

## Verification
- Run: `nix build --no-link .#bun.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
