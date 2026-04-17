---
name: add-package
description: Add a new package to the toolbox registry. Handles prebuilt binaries, source builds, or hybrid (prebuilt with source fallback) depending on what upstream provides. Use when adding a new tool to toolbox.
argument-hint: <name> [version]
allowed-tools: Bash Read Edit Write Glob Grep
---

# Add Package

Add a new package to the toolbox registry.

## Current packages

!`cd "$(git rev-parse --show-toplevel)" && ls -d packages/*/`

## Task

Add a package called `$0` at version `$1` (if provided; otherwise discover the latest version).

## Steps

### 1. Research upstream

- Find the upstream repository and releases page
- Check what release assets exist: prebuilt binaries per platform? source tarballs only?
- Determine which platforms have prebuilt binaries (x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin)
- Check the build system for source builds (Go → buildGoModule, Rust → buildRustPackage, C/Make → stdenv.mkDerivation)

### 2. Choose the builder strategy

**Prebuilt only** — all 4 platforms have prebuilt binaries (e.g. uv, biome, gh):
- `data.json` has per-platform SHA256 hashes
- `default.nix` uses `fetchurl` + `stdenv.mkDerivation` with `dontBuild = true`
- Reference: `packages/uv/default.nix`, `packages/gh/default.nix`

**Source only** — no prebuilt binaries, or user prefers source builds (e.g. jj, beadwork, git):
- `data.json` has source hash + build-specific hashes (vendorHash, cargoHash)
- `default.nix` uses `buildGoModule`, `buildRustPackage`, or `stdenv.mkDerivation`
- Reference: `packages/jj/default.nix` (Rust), `packages/beadwork/default.nix` (Go), `packages/git/default.nix` (C)

**Hybrid** — some platforms have prebuilt binaries, others need source builds (e.g. delta):
- `data.json` has per-platform hashes for prebuilt platforms, plus `srcHash`/`cargoHash`/`rust` (or `vendorHash`/`go`) for source builds
- `default.nix` has a single `default` builder that checks `if versionData ? ${system}` to pick prebuilt vs source
- Reference: `packages/delta/default.nix`

The hybrid pattern looks like:

```nix
builders = {
  default = version: versionData:
    if versionData ? ${system} then
      mkPrebuilt version versionData
    else
      mkFromSource version versionData;
};
```

Where `mkPrebuilt` and `mkFromSource` are defined as `let` bindings in the same file.

### 3. Create the package

1. `mkdir packages/$0`
2. Create `data.json` with `_meta` (default version, releases URL) and the version entry
3. Create `default.nix` following the chosen pattern
4. Compute hashes:
   - Prebuilt: `nix-prefetch-url --type sha256 --unpack <url>` then `nix hash convert --hash-algo sha256 --to sri <hash>`
   - **Important**: `nix-prefetch-url` hashes often differ from what nix uses at build time. Set the hash, attempt a build, and use the correct hash from the error if it mismatches.
   - Source (Go): set `vendorHash` to `""`, build, use hash from error
   - Source (Rust): set `cargoHash` to `""`, build, use hash from error
5. `git add packages/$0` — Nix flakes require tracked files
6. Build and verify: `nix build .#$0.default -o result-$0 && ./result-$0/bin/$0 --version`

### 4. Platform considerations

- macOS zips need `pkgs.unzip` in `nativeBuildInputs`
- Linux prebuilt binaries need `pkgs.autoPatchelfHook` and `pkgs.stdenv.cc.cc.lib`
- macOS source builds needing system frameworks use `pkgs.apple-sdk_15` (not the removed `pkgs.darwin.apple_sdk`)
- If a platform has no prebuilt and can't easily build from source, it's fine to omit it — document in `meta.platforms`

### 5. Finalize

- Create a jj change with message: `feat: add $0 <version>`
- If adding to a toolchain, that's a separate jj change
