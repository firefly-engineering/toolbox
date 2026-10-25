# protoc-gen-go

## Overview

`protoc-gen-go` built from the `protocolbuffers/protobuf-go` tag with toolbox's pinned Go via `toolboxLib.buildGoPackage`.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.protoc-gen-go`: `versions` = 1.36.11, 1.36.12; `default` = `1.36.12`.
- Builder: `builders.default = toolboxLib.buildGoPackage { ...; subPackages = [ "cmd/protoc-gen-go" ]; }`.
- Installs `bin/protoc-gen-go`.
- Cross-package dependency: `toolbox.go.versions.${versionData.go}` (default pins Go 1.27.1).

## Invariants

- Each version entry must carry `sha256` (`--unpack` hash of the tag tarball), `vendorHash` and `go` (a version key of `packages/go/data.json`).
- Go module dependencies are pinned by the fixed-output `vendorHash`.

## Side Effects

- Fixed-output fetch of the `protocolbuffers/protobuf-go` source tarball and Go modules at build time only; evaluation is offline.

## Verification

Run from the repository root:

```bash
nix build --no-link .#protoc-gen-go.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
