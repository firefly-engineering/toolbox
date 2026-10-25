# nix

## Overview

The Nix package manager built from the `NixOS/nix` tag with meson on the LLVM stdenv; a custom `mkDerivation` with one builder variant per meson flag set.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.nix`: `versions` = 2.34.7, 2.35.2; `default` = `2.35.2`.
- Builders: `default` (flags include `-Dbindings=false`) and `v2_35` (drops `-Dbindings`, adds `-Dfunctional-tests=false`); both from a local `mkNix { mesonFlags }`, built with `pkgs.llvmPackages.stdenv`.
- Version 2.35.2 selects `"builder": "v2_35"`; 2.34.7 uses `default`.
- Platforms: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.
- Common meson flags: `-Dlocalstatedir=/nix/var`, `-Ddoc-gen=false`, `-Dunit-tests=false`, `-Djson-schema-checks=false`; `mesonAutoFeatures = "auto"`; `doCheck = false`.

## Invariants

- Each version entry carries `sha256` (`--unpack` hash of the tag; the source `rev` is the bare version, with no `v` prefix) and, for 2.35+, `builder = "v2_35"`; passing `-Dbindings` to 2.35+ is a hard meson error.
- A change in build flags gets a new builder variant; existing builders are not edited under existing versions.
- Build inputs come from the pinned nixpkgs; `libcpuid` only on x86_64, `libseccomp` only on Linux.

## Side Effects

- Fixed-output fetch of the `NixOS/nix` source tarball at build time only; evaluation is offline.
- The installed `nix` defaults its state dir to `/nix/var`.

## Verification

Run from the repository root:

```bash
nix build --no-link .#nix.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
