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

**Do not hand-roll a builder.** `lib/` has a helper for each of these shapes, and
each returns a *builder function* that slots into `buildPackage`'s `builders`
attrset. Reach for `stdenv.mkDerivation` only when none of them fits.

**Prebuilt only** — the platforms you support have prebuilt binaries (e.g. uv, biome, gh, jq, ruff):
- `data.json` nests the hash per system: `{ "1.2.3": { "x86_64-linux": { "sha256": … }, … } }`
- `default.nix` uses `toolboxLib.buildPrebuiltBinary` — it hides per-system asset
  resolution, `fetchurl`, the `dontConfigure`/`dontBuild`/`dontStrip` trio, `.zip`
  unpacking, Linux `autoPatchelfHook`, and installing named executables into
  `$out/bin`. Its `platforms` table also becomes `meta.platforms`, so a tool that
  does not exist everywhere needs no extra handling.
- Reference: `packages/uv/default.nix`, `packages/gh/default.nix` (mixed
  `.tar.gz`/`.zip` per platform), `packages/jq/default.nix` (single static binary)
- Not for tools that install a whole toolchain *tree* (`nodejs`, `python`, `rust`,
  `platform-tools`) — those stay on `stdenv.mkDerivation`.

**Source only** — no prebuilt binaries, or user prefers source builds:
- `data.json` has the source hash plus the toolchain pin and dependency hash:
  `{ "rust": "1.98.1", "sha256": …, "cargoHash": … }` or
  `{ "go": "1.27.1", "sha256": …, "vendorHash": … }`
- `default.nix` uses `toolboxLib.buildRustPackage` or `toolboxLib.buildGoPackage`
  — give it `pname`, `owner`, `repo`, and put anything else in `extraArgs`
- Reference: `packages/cargo-edit/default.nix` (Rust, minimal),
  `packages/jj/default.nix` (Rust, build inputs + postInstall),
  `packages/gopls/default.nix` (Go, custom rev + sourceRoot),
  `packages/git/default.nix` (C — genuinely needs `stdenv.mkDerivation`)

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

Where `mkPrebuilt` and `mkFromSource` are `let` bindings in the same file — each
built from the corresponding helper (`buildPrebuiltBinary` / `buildRustPackage`)
rather than hand-rolled.

### 3. Create the package

1. `mkdir packages/$0`
2. Create `data.json` with `_meta` (default version, releases URL) and the version entry
3. Create `default.nix` following the chosen pattern
4. Compute hashes — match the prefetch tool to the Nix fetcher:

   **`fetchurl`** (prebuilt binaries — .tar.gz, .zip, single files):
   `fetchurl` hashes the raw downloaded file. The builder's `unpackPhase` extracts it later.
   ```bash
   nix-prefetch-url --type sha256 <url>
   nix hash convert --hash-algo sha256 --to sri <hash>
   ```
   Do NOT use `--unpack` — that hashes the extracted content, which is wrong for `fetchurl`.

   **`fetchFromGitHub`** (source builds from GitHub):
   `fetchFromGitHub` internally uses `fetchzip`, which unpacks and strips the top-level directory. The hash is of the unpacked content.
   ```bash
   nix-prefetch-url --type sha256 --unpack https://github.com/OWNER/REPO/archive/refs/tags/TAG.tar.gz
   nix hash convert --hash-algo sha256 --to sri <hash>
   ```
   Here `--unpack` IS correct because `fetchFromGitHub` hashes unpacked content.

   **`vendorHash` / `cargoHash`** (Go/Rust dependency hashes):
   These can't be computed upfront. Set to `""`, attempt a build, and use the hash from the error output.
5. `jj st` — snapshotting the working copy is what makes the new files visible
   to Nix (flakes only see tracked files)
6. Build and verify: `nix build .#$0 -o result-$0 && ./result-$0/bin/$0 --version`
7. Gate the registry: `nix flake check --all-systems` — see the Verification
   Checklist in `AGENTS.md` for the `devenv-root` override it needs. This is what
   catches a missing hash, a bad `_meta.default`, or a dangling pin, on *every*
   system rather than only yours.

### 4. Platform considerations

- macOS zips need `pkgs.unzip` in `nativeBuildInputs`
- Linux prebuilt binaries need `pkgs.autoPatchelfHook` and `pkgs.stdenv.cc.cc.lib`
- macOS source builds needing system frameworks use `pkgs.apple-sdk_15` (not the removed `pkgs.darwin.apple_sdk`)
- If a platform has no prebuilt and can't easily build from source, omit it. With
  `buildPrebuiltBinary` just leave it out of the `platforms` table — `meta.platforms`
  follows from that table, and the registry filters the package out of the flake
  outputs on systems it does not cover. On a hand-written builder, say so in
  `meta.platforms` explicitly, or the package will throw when someone forces it.
- The first two bullets above are handled for you by `buildPrebuiltBinary`; they
  only apply to a hand-written `stdenv.mkDerivation`.

### 5. Finalize

- Create a jj change with message: `feat: add $0 <version>`
- If adding to a toolchain, that's a separate jj change
