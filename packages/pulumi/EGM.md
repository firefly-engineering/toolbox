# pulumi

## Overview

Pulumi CLI and its language hosts installed from upstream's prebuilt release tarballs via `toolboxLib.buildPrebuiltBinary`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.pulumi`: `versions` = 3.255.0, 3.262.0; `default` = `3.262.0` (`_meta.default`).
- Builder: `builders.default = toolboxLib.buildPrebuiltBinary { ... }` passed to `toolboxLib.buildPackage`.
- Installs: `bin/pulumi`, `pulumi-language-{bun,dotnet,go,java,nodejs,pcl,python,python-exec,yaml}`, `pulumi-resource-pulumi-{nodejs,python}`, `pulumi-watch`. On Linux they go through `autoPatchelfHook` (default `patchelf = true`).
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Asset URL: `https://github.com/pulumi/pulumi/releases/download/v${version}/pulumi-v${version}-${platform}.tar.gz`.

## Invariants

- `data.json` nests one `{ sha256 }` per system under each version; the hash is the raw `fetchurl` hash of the release asset (no `--unpack`).
- Evaluation throws on a system missing from the `platforms` table; `meta.platforms` is derived from it, so `availableVersions` drops the package elsewhere.
- Tarball unpacks to `pulumi/` (`sourceRoot = "pulumi"`); the CLI finds language hosts next to itself, so all binaries must land in `$out/bin` together.

## Side Effects

- Fixed-output fetch of the per-system release asset at build time only; evaluation is offline.
- At runtime the CLI spawns the `pulumi-language-*` hosts and talks to cloud providers / the Pulumi service.

## Verification

Run from the repository root:

```bash
nix build --no-link .#pulumi.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
