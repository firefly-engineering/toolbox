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

- **pnpm** (`pnpm-lock.yaml`): use `buildNpmPackage` with `npmDeps = null` and `pnpmDeps = fetchPnpmDeps { … }`. Match the pnpm major version to the repo's `packageManager` field (`pnpm@9.x` → `pkgs.pnpm_9`); the lockfile's `lockfileVersion` must be readable by that pnpm or the fetcher errors. Set `fetcherVersion = 3` (reproducible tarball). Reference: `packages/openspec/`:
  ```nix
  pkgs.buildNpmPackage (finalAttrs: {
    pname = "openspec";
    inherit version;
    src = pkgs.fetchFromGitHub { owner = "…"; repo = "…"; rev = "v${version}"; hash = versionData.sha256; };
    npmDeps = null;
    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pkgs.pnpm_9;
      fetcherVersion = 3;
      hash = versionData.pnpmDeps;   # the only dep hash in data.json
    };
    nativeBuildInputs = [ pkgs.pnpm_9 ];
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
│   └── default.nix        # Registry helpers (resolveTool, readData, buildVersions, buildToolchain, resolvePatches, versionToAttr)
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
- **`_meta.releases`**: URL to the upstream releases page (e.g., GitHub releases, official download page). Used by the docs generator to link package names, and by agents to check for new versions.
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
  inherit (toolboxLib.readData ./data.json) meta versions;

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
{
  versions = toolboxLib.buildVersions "mypackage" builders versions;
  default = meta.default;
}
```

### 4. Test

The package is auto-discovered — no changes to `flake.nix` needed:

```bash
nix build .#mypackage.default
nix build .#mypackage.1_0_0   # Version dots become underscores
```

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

## Verification Checklist

After making changes:

1. `nix flake check` — no evaluation errors
2. `nix build .#<pkg>.default` — default version builds
3. `nix build .#<pkg>.<version>` — specific version builds
4. Verify binary output with `./result/bin/<binary> --version` or similar
5. `nix eval .#registry.x86_64-linux --apply 'r: builtins.mapAttrs (n: v: builtins.attrNames v.versions) r' --json` — verify registry shape

## Work Management

This project tracks work with `bw` (beadwork), which persists to git  plans, progress, and decisions survive
compaction, session boundaries, and context loss.

ALWAYS run `bw prime` before starting work. Without it, you're missing workflow context, current state, and repo
hygiene warnings. Work done without priming often conflicts with in-progress changes.

Committing, closing issues, and syncing are part of completing a task  not separate actions requiring additional
permission.