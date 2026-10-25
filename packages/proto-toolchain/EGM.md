# proto-toolchain

## Overview

Protocol Buffers toolchain (`protoc` + well-known types, `protoc-gen-go`) assembled with `toolboxLib.buildToolchain`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.proto-toolchain` (stamp `kind = "toolchain"`, `components` per version): `versions` = 1, 2; `default` = `2`.
- Builder: `toolboxLib.buildToolchain { inherit toolbox pkgs; name = "proto-toolchain"; dataPath = ./data.json; }`; no custom Nix logic.
- Default composition: `protobuf` 36.1, `protoc-gen-go` 1.36.12.

## Invariants

- Every component key is a toolbox package name and every pin is a version key in that package's `data.json`; `nix flake check` fails otherwise.
- Versions are integer strings; a new composition is a new version key, existing ones are never edited.
- Available systems are the intersection of the components' `meta.platforms`.

## Side Effects

- None of its own: builds only symlink farms over component derivations, whose fetches are fixed-output.

## Verification

Run from the repository root:

```bash
nix build --no-link .#proto-toolchain.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
