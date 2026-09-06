# AGENTS.md - Guide for Adding Packages to Toolbox

## Overview

Toolbox is a self-contained, data-driven package registry for [turnkey](https://github.com/firefly-engineering/turnkey). Version metadata lives in JSON data files — Nix code reads this data to build derivations automatically. Adding a new version means adding a JSON entry, not editing Nix code.

## Reproducibility Is Non-Negotiable

Every derivation must build identically from pinned inputs, forever. A build whose output depends on *when* it runs is a bug, not a convenience.

- **Pin everything by content hash.** Source archives (`sha256`), Go deps (`vendorHash`), Rust deps (`cargoHash`), and dependency trees are all fixed-output. Never leave a hash to be resolved "live" at build time.
- **Never resolve version ranges at build time.** If a package's dependencies are expressed as semver *ranges* (npm `^`/`~`, etc.), resolving them during the build ties the output to the registry's state on that day — a rebuild months later can silently pull different transitive versions. This is unacceptable. The fully-resolved tree must come from a **lockfile** (see below).
- **Use upstream's own lockfile.** Upstream already resolved and tested a specific dependency tree; their committed lockfile is the source of truth. Do not regenerate or re-resolve it — build from the source tree that contains it so a Nix dep-fetcher consumes it directly.
- **Fail loudly, never drift silently.** Prefer tools that verify a lockfile (`npm ci`, `pnpm --frozen-lockfile`, `cargo --locked`) over ones that will happily update it. If pinned inputs no longer match, the build must error, not paper over it.

The failure mode to design against: "it built for me today." If it won't build byte-identically in a year, it isn't done.

### Node/JS Packages (npm, pnpm, yarn)

**Build from the tagged source repository, not the published npm tarball.** The npm registry tarball ships compiled output but usually no lockfile, which would force you to re-resolve dependencies — exactly what must not happen. The source repo contains the committed lockfile; build from it so a Nix dep-fetcher pins the tree upstream actually tested.

Pick the fetcher by the lockfile upstream commits:

- **pnpm** (`pnpm-lock.yaml`): use `buildNpmPackage` with `npmDeps = null` and `pnpmDeps = fetchPnpmDeps { … }`. Drive the install with **toolbox's own pinned pnpm** (`toolbox.pnpm.versions.${versionData.pnpm}`), not nixpkgs' — upstream's `packageManager` field often names an EOL pnpm that nixpkgs marks insecure, and what actually has to hold is that the pnpm you use can read the lockfile's `lockfileVersion`, not that it matches upstream's major. Set `fetcherVersion = 4` (reproducible tarball). Reference: `packages/openspec/`:
  ```nix
  pkgs.buildNpmPackage (finalAttrs: {
    pname = "openspec";
    inherit version;
    src = pkgs.fetchFromGitHub { owner = "…"; repo = "…"; rev = "v${version}"; hash = versionData.sha256; };
    npmDeps = null;
    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;                  # toolbox.pnpm.versions.${versionData.pnpm}
      fetcherVersion = 4;
      hash = versionData.pnpmDeps;   # the only dep hash in data.json
    };
    nativeBuildInputs = [ pnpm ];
    npmConfigHook = pkgs.pnpmConfigHook;
    dontNpmPrune = true;             # node_modules is pnpm-managed
  });
  ```
- **npm** (`package-lock.json`): plain `buildNpmPackage` with `npmDepsHash = versionData.npmDepsHash;` (it reads the committed lock via `fetchNpmDeps`).
- **yarn** (`yarn.lock`): `fetchYarnDeps` / `yarnConfigHook`.

The dep hash (`pnpmDeps`/`npmDepsHash`) can't be precomputed — set it to `lib.fakeHash` (`sha256-AAAA…`), build, and copy the `got:` value into `data.json`. The dep-fetcher FODs already include `pkgs.cacert`, so TLS works.

**Last resort — vendoring a lockfile.** Only when upstream ships *no* usable lockfile anywhere (not in the repo, not in the tarball) may you generate one. Then vendor it **version-namespaced** like a patch — `package-lock-<version>.json` (never a shared name), generated with `npm install --package-lock-only --ignore-scripts`, referenced as `${./. + "/package-lock-${version}.json"}`, and installed with `npm ci` (never `npm install`). A vendored, self-generated lock is strictly worse than upstream's — it pins *a* tree, not *the tested* tree — so reach for it only when there is no alternative, and say so in a comment.

## Repository Structure

```
toolbox/
├── flake.nix              # Flake assembly: auto-discovers packages/, exposes registry + packages
├── lib/
│   ├── default.nix        # Registry helpers (resolveTool, readData, buildPackage, buildVersions, buildToolchain, resolvePatches, availableVersions, versionToAttr)
│   ├── prebuilt-binary.nix # buildPrebuiltBinary: tools shipped as prebuilt per-platform binaries
│   ├── rust-package.nix   # buildRustPackage: Rust built from a tagged GitHub source
│   ├── go-package.nix     # buildGoPackage: Go built from a tagged GitHub source
│   ├── skill-bundle.nix   # buildSkillBundle: Claude Code skill bundles
│   └── check-registry.nix # checkRegistry: eval-time invariants, wired to `nix flake check`
└── packages/
    ├── go/
    │   ├── default.nix    # Go builder: builds Go from source using pkgs.go as bootstrap
    │   └── data.json      # Version metadata: { "1.25.6": { "sha256": "..." } }
    └── beads/
        ├── default.nix    # Beads builder: buildGoModule with toolbox Go
        └── data.json      # Version metadata: { "0.52.0": { "sha256": "...", "go": "1.25.6" } }
```

## data.json Schema

Each package directory has a `data.json` with version entries and a `_meta` key:

```json
{
  "_meta": { "default": "1.2.3", "releases": "https://github.com/OWNER/REPO/releases" },
  "1.2.3": {
    "sha256": "sha256-XXXX",
    "vendorHash": "sha256-YYYY"
  }
}
```

- **`_meta.default`**: Which version is the default (used by `nix build .#<pkg>.default`)
- **`_meta.releases`**: URL to the upstream releases page (e.g., GitHub releases, official download page). Read by the builder into the entry's `toolbox` stamp, from which the docs generator links package names; also used by agents to check for new versions.
- **`_meta.inactive`**: (optional) When `true`, the package is no longer actively maintained — no new versions will be added. Existing versions remain fully functional. Inactive packages are skipped by update checks and shown with reduced emphasis in generated docs. To mark a package inactive, add `"inactive": true` to its `_meta` object.
- **Version keys**: Semantic version strings (e.g., `"1.25.6"`, `"0.52.0"`)
- **`sha256`**: SRI hash of the source archive
- **`vendorHash`**: (Go packages) SRI hash of vendored dependencies
- **`go`**: (Go packages) Go version from toolbox to build with
- **`builder`**: (optional) Builder variant name; defaults to `"default"`

## Adding a New Version of an Existing Package

### 1. Compute the source hash

**Match the prefetch tool to the Nix fetcher used in `default.nix`:**

For `fetchFromGitHub` / `fetchzip` (hashes unpacked content — use `--unpack`):
```bash
nix-prefetch-url --type sha256 --unpack https://github.com/OWNER/REPO/archive/refs/tags/vX.Y.Z.tar.gz
nix hash convert --hash-algo sha256 --to sri <hash>
```

For `fetchurl` (hashes the raw downloaded file — do NOT use `--unpack`):
```bash
nix-prefetch-url --type sha256 https://example.com/package-X.Y.Z.tar.gz
nix hash convert --hash-algo sha256 --to sri <hash>
```

`fetchurl` downloads the file as-is; the builder's `unpackPhase` extracts it. `fetchFromGitHub` unpacks and strips the top-level directory before hashing. Using the wrong prefetch mode produces a hash mismatch at build time.

### 2. Add the version entry to `data.json`

```json
{
  "_meta": { "default": "0.53.0" },
  "0.53.0": {
    "sha256": "sha256-COMPUTED_HASH",
    "vendorHash": "sha256-VENDOR_HASH",
    "go": "1.25.6"
  },
  "0.52.0": { ... }
}
```

Update `_meta.default` if this should be the new default.

### 3. Verify the vendorHash

If you don't know the vendorHash, set it to `""` and attempt a build:

```bash
nix build .#beads.0_53_0
```

The build will fail with a message like:
```
hash mismatch in fixed-output derivation ...
  got:    sha256-ACTUAL_HASH
```

Use the "got:" hash as the `vendorHash`.

### 4. Test the build

```bash
nix build .#beads.0_53_0
./result/bin/bd version
```

## Adding a New Package

### 1. Create the package directory

```bash
mkdir packages/mypackage
```

### 2. Create `data.json`

```json
{
  "_meta": { "default": "1.0.0", "releases": "https://github.com/OWNER/REPO/releases" },
  "1.0.0": {
    "sha256": "sha256-XXXX"
  }
}
```

### 3. Create `default.nix`

The builder must be a function that takes `{ pkgs, lib, toolbox, toolboxLib }` and returns:

```nix
{
  versions = { "1.0.0" = <derivation>; ... };
  default = "1.0.0";  # Must match _meta.default
}
```

Full template:

```nix
{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      pkgs.stdenv.mkDerivation {
        pname = "mypackage";
        inherit version;
        src = pkgs.fetchurl {
          url = "https://example.com/mypackage-${version}.tar.gz";
          hash = versionData.sha256;
        };
        # ... build steps ...
      };
  };
in
toolboxLib.buildPackage { name = "mypackage"; dataPath = ./data.json; inherit builders; }
```

`toolboxLib.buildPackage` is the canonical entry point for versioned packages: it reads `meta` + `versions` from `data.json`, dispatches each version through `builders` (keyed by the optional `"builder"` field — see *Builder Versioning*), and returns the `{ versions; default; }` shape the registry expects. It's the same shape `buildToolchain` and `buildSkillBundle` produce.

**A package that does not exist everywhere does not need an escape hatch.** Declare where it exists — `meta.platforms`, which `buildPrebuiltBinary` derives from its `platforms` table for free — and `toolboxLib.availableVersions` filters it out of the flake outputs on every other system. `buildToolchain` intersects its components' platforms, so a toolchain inherits the constraint. Do not hand-build the `{ versions; default; }` return to work around this; every package in the registry goes through `buildPackage`.

`toolboxLib.buildVersions` remains available for a package that must genuinely pre-process its version set before building, but nothing in the registry currently needs it.

### 4. Test

The package is auto-discovered — no changes to `flake.nix` needed:

```bash
nix build .#mypackage.default
nix build .#mypackage.1_0_0   # Version dots become underscores
```

## Prebuilt-Binary Packages

Tools distributed as prebuilt per-platform binaries or archives (no source build) use `toolboxLib.buildPrebuiltBinary`, which returns a **builder function** that slots into `buildPackage`'s `builders` attrset. It hides the invariant ritual — per-system asset resolution with a throw on unsupported platforms, `fetchurl` against `versionData.<system>.sha256`, the `dontConfigure`/`dontBuild`/`dontStrip` trio, optional Linux `autoPatchelfHook`, `.zip` unpacking, and installing named executables into `$out/bin`:

```nix
{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "jq";
    platforms = {
      "x86_64-linux"   = "linux-amd64";
      "aarch64-linux"  = "linux-arm64";
      "x86_64-darwin"  = "macos-amd64";
      "aarch64-darwin" = "macos-arm64";
    };
    url = { version, platform }:
      "https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${platform}";
    binaries = [ "jq" ];
    patchelf = false;   # static binary
    meta = with lib; { description = "…"; homepage = "…"; license = licenses.mit; };
  };
in
toolboxLib.buildPackage { name = "jq"; dataPath = ./data.json; inherit builders; }
```

The `data.json` for a prebuilt package nests the source hash **per system** (one binary per platform):

```json
{
  "_meta": { "default": "1.8.2", "releases": "https://github.com/jqlang/jq/releases" },
  "1.8.2": {
    "x86_64-linux":   { "sha256": "sha256-…" },
    "aarch64-linux":  { "sha256": "sha256-…" },
    "x86_64-darwin":  { "sha256": "sha256-…" },
    "aarch64-darwin": { "sha256": "sha256-…" }
  }
}
```

### Parameters

| Param | Required | Meaning |
|---|---|---|
| `pkgs` | yes | nixpkgs instance |
| `pname` | yes | package name |
| `platforms` | yes | `system -> asset string`; throws on unsupported system |
| `url` | yes | `{ version, platform } -> URL` |
| `binaries` | yes | executables to install into `$out/bin`; each entry a string (installed under its basename) or `{ from; to; }` to rename — `from` may be a fn `{ version, platform } -> string` for assets whose binary is named e.g. `tool-${version}-${triple}` |
| `sourceRoot` | no | `null` (default) → single binary (`dontUnpack`); a transport-compression suffix (`.zst`/`.gz`/`.xz`/`.bz2`) is auto-detected and the binary decompressed. Else a string, or fn `{ version, platform } -> string`, naming the unpacked dir (`"."` for a flat tarball). `.zip` archives get `unzip` automatically |
| `patchelf` | no | Linux `autoPatchelfHook` + `cc.cc.lib` (default `true`; set `false` for static binaries) |
| `extraLibs` | no | extra shared libraries for `autoPatchelfHook` to resolve on Linux (e.g. `[ pkgs.zlib ]` for `libz.so.1`); ignored when `patchelf = false` |
| `symlinks` | no | `{ link = target; }` → `$out/bin/<link>` → `$out/bin/<target>` |
| `postInstall` | no | extra shell appended inside `installPhase` (shell completions, man pages, shipped asset trees, relative symlinks) |
| `meta` | no | derivation meta |

### When *not* to use it

`buildPrebuiltBinary` installs *named executables* — including single binaries shipped transport-compressed (`.zst`/`.gz`/`.xz`/`.bz2`, decompressed automatically; e.g. `buck2`, `rust-analyzer`). Tools that install a whole toolchain tree (`nodejs`, `python`, `rust`, `git`, `platform-tools`, `typescript`) stay on plain `mkDerivation` — they're a different shape.

## Source-Built Rust and Go Packages

Rust and Go packages built from a tagged GitHub source use
`toolboxLib.buildRustPackage` / `toolboxLib.buildGoPackage`. Like
`buildPrebuiltBinary`, each returns a **builder function** that slots into
`buildPackage`'s `builders` attrset, so the package can still grow builder
variants. They hide the invariant ritual — resolving the pinned toolchain out
of the registry (`versionData.rust` / `versionData.go`), constructing the
platform (`makeRustPlatform` / `buildGoModule.override`), fetching the tagged
source, and wiring `versionData`'s hashes in.

```nix
{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "cargo-edit";
    owner = "killercup";
    repo = "cargo-edit";
    extraArgs = {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
    };
    meta = with lib; { description = "…"; homepage = "…"; license = licenses.mit; };
  };
in
toolboxLib.buildPackage { name = "cargo-edit"; dataPath = ./data.json; inherit builders; }
```

`buildGoPackage` takes the same shape, plus `subPackages` (default `[ "." ]`,
overridden by `versionData.subPackages` when the data supplies it).

### Parameters

| Param | Required | Meaning |
|---|---|---|
| `pkgs` | yes | nixpkgs instance |
| `toolbox` | yes | the registry, for the pinned Rust/Go |
| `pname` | yes | package name |
| `owner` / `repo` | yes | GitHub source |
| `rev` | no | fn `{ version } -> rev` (default `"v${version}"`); e.g. `nil` uses a bare `version`, `gopls` uses `"gopls/v${version}"` |
| `subPackages` | no | *(Go only)* build targets, default `[ "." ]` |
| `extraArgs` | no | extra builder arguments — an attrset, or a fn `{ version, versionData, rust\|go } -> attrset` when the version or the resolved toolchain is needed. Merged last, so it overrides anything the helper sets |
| `meta` | no | derivation meta |

### Dependency pinning follows the data

`buildRustPackage` sets `cargoHash` from `versionData.cargoHash` when the data
carries one. A package vendoring a lockfile instead has no `cargoHash` in its
`data.json` and supplies `cargoLock` through `extraArgs` — see `packages/nil`
(version-namespaced `Cargo-${version}.lock`) and `packages/qmk_hid`.

`buildGoPackage` always reads `versionData.vendorHash`.

### When *not* to use them

Packages whose build is not "fetch a tagged GitHub tag and compile it" stay on
their own builders: `packages/go` (bootstraps Go from source), `packages/nix`
(meson), `packages/delta` (prebuilt with a source fallback, dispatching on
whether the data has an entry for this system).

## Adding a New Toolchain

Toolchains are meta-packages that bundle related tools via `symlinkJoin`. They use `toolboxLib.buildToolchain` — no custom Nix logic needed.

### 1. Create the package directory

```bash
mkdir packages/my-toolchain
```

### 2. Create `data.json`

Component keys must match toolbox package names exactly:

```json
{
  "_meta": { "default": "1" },
  "1": {
    "mytool": "1.0.0",
    "myformatter": "2.3.4"
  }
}
```

### 3. Create `default.nix`

```nix
{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildToolchain { inherit toolbox pkgs; name = "my-toolchain"; dataPath = ./data.json; }
```

### 4. Test

```bash
nix build .#my-toolchain.default
nix build .#my-toolchain.1
```

## Adding a Skill Bundle

A *skill bundle* packages agent skills from a pinned upstream repository into a Claude Code **plugin directory** — `.claude-plugin/plugin.json` plus the selected skill directories. Downstream consumers wire the result into home-manager's `programs.claude-code` module as either a whole plugin or a flattened set of skills.

The generic support code is `toolboxLib.buildSkillBundle` (in `lib/skill-bundle.nix`); each bundle package is thin and data-driven, like a toolchain.

### Reproducibility

Skill *selection* happens inside the build sandbox with `jq` (a real JSON parser) reading the upstream `.claude-plugin/plugin.json` — never at Nix evaluation time. There is no import-from-derivation, and the output is a pure function of the pinned source hash. Which skills end up in the bundle can never depend on *when* the build runs.

### 1. Compute the source hash

The builder uses `fetchFromGitHub`, so prefetch with `--unpack` and pin a **commit** — a plugin's `version` field and its git tags drift independently (`main` may already be a version ahead of the newest tag):

```bash
nix-prefetch-url --type sha256 --unpack https://github.com/OWNER/REPO/archive/<commit>.tar.gz
nix hash convert --hash-algo sha256 --to sri <hash>
```

### 2. Create `data.json`

```json
{
  "_meta": {
    "default": "1.1.0",
    "releases": "https://github.com/OWNER/REPO/releases",
    "fromClaudePlugin": true
  },
  "1.1.0": {
    "owner": "OWNER",
    "repo": "REPO",
    "rev": "<commit-sha>",
    "sha256": "sha256-XXXX"
  }
}
```

Per-version fields:

- **`owner` / `repo` / `rev` / `sha256`**: the `fetchFromGitHub` source pin (`rev` is a commit).
- **`fromClaudePlugin`**: (bool) when `true`, include only the skills listed in the upstream manifest's `skills` array — repo extras (`skills/deprecated`, `skills/in-progress`, …) are dropped, and the upstream manifest is shipped verbatim with its `skills` array rewritten to the selection. When `false`, include every directory under `skills/` that contains a `SKILL.md`, and synthesize a `{ name, skills }` manifest. Defaults from `_meta.fromClaudePlugin`, else `false`.
- **`pluginJsonPath`**: (optional) manifest location; defaults to `.claude-plugin/plugin.json`.
- **`select`** / **`exclude`**: (optional) allowlist / denylist of skill *basenames*, applied on top of the above. `exclude` wins over `select`.

`_meta.fromClaudePlugin` sets the package-wide default; a version entry may override it.

### 3. Create `default.nix`

```nix
{ pkgs, lib, toolbox, toolboxLib }:

toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "mypackage-skills";
  dataPath = ./data.json;
}
```

### 4. Test

```bash
nix build .#mypackage-skills.default            # the plugin directory
nix build .#mypackage-skills.1_1_0
jq '{name, count: (.skills | length)}' result/.claude-plugin/plugin.json
nix build .#mypackage-skills.skills             # flattened one-folder-per-skill view (passthru)
```

### Consuming from home-manager

The bundle derivation *is* a plugin directory, and it exposes a flattened `passthru.skills` for the path form of the `skills` option (which cannot consume the upstream category nesting):

```nix
# As a plugin — the manifest drives what Claude Code loads:
programs.claude-code.plugins = [ inputs.toolbox.packages.${system}.mypackage-skills ];

# As a flat skills directory:
programs.claude-code.skills = "${inputs.toolbox.packages.${system}.mypackage-skills.skills}";
```

Use one route, not both. The `plugins` route requires Claude Code ≥ 2.1.76 (≥ 2.1.157 for persistent personal plugins); the `skills` route has no version floor. Both need a home-manager recent enough to expose `programs.claude-code.skills` / `.plugins`.

### Bundling into a toolchain

A skill bundle can be a component of a toolchain (see *Adding a New Toolchain*); its `skills/` and `.claude-plugin/` trees are symlinked into the toolchain output alongside the other tools. Only **one** skill bundle per toolchain, though — `symlinkJoin` cannot merge two `.claude-plugin/plugin.json` files.

## Builder Versioning

When the build process changes across versions (new flags, different structure), add a new builder variant instead of modifying the existing one:

```json
{
  "_meta": { "default": "2.0.0" },
  "1.0.0": {
    "sha256": "sha256-XXXX"
  },
  "2.0.0": {
    "sha256": "sha256-YYYY",
    "builder": "v2"
  }
}
```

In `default.nix`:

```nix
builders = {
  default = version: versionData: { ... };  # Original build logic
  v2 = version: versionData: { ... };       # New build logic
};
```

When `"builder"` is absent, it defaults to `"default"`. Existing versions are never affected by new builders.

## Applying Patches from a Fork

Some packages augment upstream releases with custom patches from a fork. Patches are vendored in the repository for reproducibility, with metadata about their origin for scripted regeneration.

### data.json schema for patches

```json
{
  "_meta": { "default": "1.0.0", "releases": "https://github.com/OWNER/REPO/releases" },
  "1.0.0": {
    "sha256": "sha256-XXXX",
    "subPackages": ["cmd/tool", "cmd/tool-extra"],
    "patches": [
      {
        "file": "patches/my-fork-1.0.0.patch",
        "source": {
          "owner": "FORK_OWNER",
          "repo": "REPO",
          "branch": "feature-branch",
          "commit": "abc123..."
        }
      }
    ]
  }
}
```

- **`patches[].file`**: Version-specific path relative to the package directory. This is what Nix reads at build time. The filename should include the base version (e.g. `my-fork-1.0.0.patch`) since each upstream release needs its own patch.
- **`patches[].source`**: Origin metadata for regeneration — not used by Nix, but used by agents/scripts to refresh the patch.
- **`subPackages`**: Optional, data-driven list of build targets. When absent, the builder uses its own default.

### Using patches in a builder

Builders opt in to patch support via `toolboxLib.resolvePatches`:

```nix
(pkgs.buildGoModule.override { inherit go; }) {
  pname = "mypackage";
  inherit version;
  src = pkgs.fetchFromGitHub { ... };
  patches = toolboxLib.resolvePatches ./. versionData;  # [] when no patches
  subPackages = versionData.subPackages or [ "cmd/tool" ];
  # ...
};
```

`resolvePatches` returns `[]` when `versionData.patches` is absent, so it's safe to add unconditionally — existing versions without patches are unaffected.

### Generating, refreshing, or rebasing patches

Use the `/manage-patches` skill to manage the full patch lifecycle:

```
/manage-patches refresh beadwork          # refresh patch for default version
/manage-patches refresh beadwork 0.12.3   # refresh patch for specific version
/manage-patches rebase beadwork 0.13.0    # create patch for new upstream version
/manage-patches init mypackage 1.0.0 fork-owner repo branch  # set up patches on a new package
```

The skill runs `generate-patch` (bundled in the skill directory), which fetches the diff from GitHub, verifies it applies cleanly, and updates the commit SHA in `data.json`. It then handles staging, building, and vendorHash discovery.

## Cross-Package Dependencies

Packages can reference other toolbox packages via the `toolbox` argument:

```nix
{ pkgs, lib, toolbox, toolboxLib }:

# Get a specific Go version from toolbox
go = toolbox.go.versions.${versionData.go};

# Use it in buildGoModule
(pkgs.buildGoModule.override { inherit go; }) { ... }
```

The `toolbox` attrset contains all packages. Lazy evaluation prevents circular dependencies as long as the dependency graph is acyclic.

## Flake Outputs

```
registry.<system>.<pkg>.versions.<version>  # Derivation
registry.<system>.<pkg>.default             # Default version string

packages.<system>.<pkg>.<version_underscored>  # Derivation (dots → underscores)
packages.<system>.<pkg>.default                # Default version derivation
```

Examples:
```bash
nix build .#go.1_25_6          # Go 1.25.6
nix build .#beads.default      # Default beads version
nix build .#beads.0_52_0       # Beads v0.52.0
nix run .#beads.default -- version
```

## Consuming from Turnkey

```nix
# In turnkey's flake.nix:
inputs.toolbox.url = "github:firefly-engineering/toolbox";

# In registryExtensions:
registryExtensions = {
  beads = inputs.toolbox.registry.${system}.beads;
  go = inputs.toolbox.registry.${system}.go;
};
```

## Checking for Package Updates

Each package's `data.json` has a `_meta.releases` URL pointing to its upstream releases page. Use this to discover whether newer versions are available.

### Checking a single package

1. Read `packages/<pkg>/data.json` to find `_meta.releases` and `_meta.default` (the current default version). If `_meta.inactive` is `true`, the package is no longer maintained — skip it.
2. Fetch the releases URL to find the latest available version(s).
   - **GitHub releases pages** (`github.com/<owner>/<repo>/releases`): use the GitHub API for structured data:
     ```bash
     gh api repos/<owner>/<repo>/releases/latest --jq '.tag_name'
     ```
     Or to list recent releases:
     ```bash
     gh api repos/<owner>/<repo>/releases --jq '.[].tag_name' | head -10
     ```
   - **Non-GitHub pages** (e.g., `go.dev/dl/`, `nodejs.org`, `static.rust-lang.org`): fetch the page and extract version information from it.
3. Compare the latest upstream version against `_meta.default`. Note that some packages use a `v` prefix in their version keys (e.g., `"v1.5.1"`) — match the convention already used in that package's `data.json`.

### Checking all packages for updates

To scan the entire registry for outdated packages:

1. Iterate over every `packages/*/data.json`.
2. For each, extract `_meta.releases` and `_meta.default`.
3. **Skip inactive packages** — if `_meta.inactive` is `true`, skip the package entirely.
4. Fetch the upstream releases URL and compare.
5. Report which packages have newer versions available, showing current vs. latest.

### Bumping a package to a new version

Once you've identified that a newer version exists:

1. Follow the steps in "Adding a New Version of an Existing Package" above.
2. Use the URL patterns in the package's `default.nix` to construct the correct download URL for the new version — this tells you how to compute the source hash.
3. Update `_meta.default` to the new version.
4. Test the build and verify the binary.

## Binary Cache (Cachix)

Toolbox packages are cached on [Cachix](https://app.cachix.org/cache/firefly-toolbox) (`firefly-toolbox`). The flake's `nixConfig` automatically configures downstream consumers to use this cache.

### Pushing all packages to the cache

```bash
nix build --no-link --print-out-paths --impure --expr '
  builtins.attrValues (builtins.getFlake (toString ./.)).packages.aarch64-darwin
' | cachix push firefly-toolbox
```

Replace `aarch64-darwin` with the target system (e.g., `x86_64-linux`) as needed.

## What the Registry Publishes

Every registry entry carries a `toolbox` stamp alongside its versions — the
facts about a package that only its *builder* knows:

```nix
{
  versions = { ... };
  default = "1.2.3";
  toolbox = {
    kind = "package";      # | "toolchain" | "skill-bundle"
    releases = "https://github.com/OWNER/REPO/releases";   # from _meta
    inactive = false;                                      # from _meta
    components = null;     # toolchains: { <version> = { <component> = <pin>; }; }
  };
}
```

`buildPackage`, `buildToolchain` and `buildSkillBundle` stamp this for you, so
an ordinary package needs to do nothing. **If you hand-build a
`{ versions; default; }` return, you must stamp it too** — `toolboxLib.mkStamp`
does it, and `checkRegistry` will fail the build if you don't.
`packages/solana-toolchain/default.nix` is the one example in the registry.

`nix eval --json .#manifest` serialises the whole registry from these stamps,
plus each version and the systems it is actually available on. The docs
generator consumes that manifest; it does **not** read `packages/*/data.json`.
Two consequences worth knowing:

- A package does not need a `data.json` of its own to be documented — see
  `packages/tuicr-skills/`, which builds from a sibling's data file and has no
  data file at all.
- `_meta.releases` and `_meta.inactive` reach the site through the stamp, so
  they are read by Nix now, not only by the docs.

See [ADR 0004](docs/adr/0004-registry-publishes-its-own-classification.md) for
why classification moved here.

## Verification Checklist

After making changes:

1. **`nix flake check`** — the registry gate. Runs
   `toolboxLib.checkRegistry` (`lib/check-registry.nix`), which forces every
   system the flake advertises, not just yours, and instantiates every version
   without building it. This is what catches a version entry missing the hash its
   builder dereferences, a `builder` naming no builder, a `_meta.default` that
   is not among the versions, a toolchain component or cross-package pin
   resolving to nothing, and a `patches[].file` that is not on disk.

   devenv needs the working directory passed in, the same way the justfile's
   `build-devshell` recipe does:

   ```bash
   printf '%s' "$PWD" > .devenv-root
   nix flake check --impure \
     --override-input devenv-root "file+file://$PWD/.devenv-root"
   ```

   **Do not add `--all-systems`.** The check derivation is native, and the
   cross-system coverage comes from what it *forces* during evaluation.
   `--all-systems` additionally asks your machine to *build* the other
   systems' check derivations, which fails with "platform mismatch": a
   derivation can be instantiated anywhere, but only realised on its own
   system.

2. `nix build .#<pkg>` — default version builds (`.#<pkg>.<version>` for a specific one)
3. Verify binary output with `./result/bin/<binary> --version` or similar
4. **Refactoring a builder?** Compare derivation paths before and after — a
   behaviour-preserving change must not move a single one:

   ```bash
   nix eval --json --impure --expr '
     let f = builtins.getFlake (toString ./.);
         pkgs = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
         tl = import ./lib { inherit (pkgs) lib; };
     in pkgs.lib.mapAttrs (_: e:
          pkgs.lib.mapAttrs (_: d: d.drvPath)
            (tl.availableVersions pkgs.stdenv.hostPlatform e))
        f.registry.${builtins.currentSystem}'
   ```

## Work Management

This project tracks work with `bw` (beadwork), which persists to git  plans, progress, and decisions survive
compaction, session boundaries, and context loss.

ALWAYS run `bw prime` before starting work. Without it, you're missing workflow context, current state, and repo
hygiene warnings. Work done without priming often conflicts with in-progress changes.

Committing, closing issues, and syncing are part of completing a task  not separate actions requiring additional
permission.
## Agent skills

### Issue tracker

Issues are tracked with beadwork (`bw`), a git-native tracker; IDs are `tb-XYZ` and live on the `beadwork` branch. PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), applied via `bw label`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
