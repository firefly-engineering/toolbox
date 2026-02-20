# AGENTS.md - Guide for Adding Packages to Toolbox

## Overview

Toolbox is a self-contained, data-driven package registry for [turnkey](https://github.com/firefly-engineering/turnkey). Version metadata lives in JSON data files — Nix code reads this data to build derivations automatically. Adding a new version means adding a JSON entry, not editing Nix code.

## Repository Structure

```
toolbox/
├── flake.nix              # Flake assembly: auto-discovers packages/, exposes registry + packages
├── lib/
│   └── default.nix        # Registry helpers (resolveTool, readData, buildVersions, versionToAttr)
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
  "_meta": { "default": "1.2.3" },
  "1.2.3": {
    "sha256": "sha256-XXXX",
    "vendorHash": "sha256-YYYY"
  }
}
```

- **`_meta.default`**: Which version is the default (used by `nix build .#<pkg>.default`)
- **Version keys**: Semantic version strings (e.g., `"1.25.6"`, `"0.52.0"`)
- **`sha256`**: SRI hash of the source archive
- **`vendorHash`**: (Go packages) SRI hash of vendored dependencies
- **`go`**: (Go packages) Go version from toolbox to build with
- **`builder`**: (optional) Builder variant name; defaults to `"default"`

## Adding a New Version of an Existing Package

### 1. Compute the source hash

For a Go source tarball:
```bash
nix-prefetch-url --type sha256 --unpack https://go.dev/dl/go1.25.7.src.tar.gz
# Convert to SRI: nix hash convert --hash-algo sha256 --to sri <hash>
```

For a GitHub release:
```bash
nix-prefetch-url --type sha256 --unpack https://github.com/OWNER/REPO/archive/refs/tags/vX.Y.Z.tar.gz
nix hash convert --hash-algo sha256 --to sri <hash>
```

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
  "_meta": { "default": "1.0.0" },
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

## Verification Checklist

After making changes:

1. `nix flake check` — no evaluation errors
2. `nix build .#<pkg>.default` — default version builds
3. `nix build .#<pkg>.<version>` — specific version builds
4. Verify binary output with `./result/bin/<binary> --version` or similar
5. `nix eval .#registry.x86_64-linux --apply 'r: builtins.mapAttrs (n: v: builtins.attrNames v.versions) r' --json` — verify registry shape
