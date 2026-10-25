# gotestsum

## Overview
Builds [gotestsum](https://github.com/gotestyourself/gotestsum), a human-friendly runner for `go test`, from its tagged source via `toolboxLib.buildGoPackage`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildGoPackage { owner = "gotestyourself"; repo = "gotestsum"; ... }` (default `rev = "v<version>"`, `subPackages = [ "." ]`), passed to `toolboxLib.buildPackage`.
- Installs `$out/bin/gotestsum` (`meta.mainProgram = "gotestsum"`).
- `data.json`: version `1.13.0` (default, go 1.26.2).
- Cross-package dependency: `toolbox.go.versions.${versionData.go}` ([go](../go/EGM.md)). Consumed by [go-toolchain](../go-toolchain/EGM.md).

## Invariants
- Each version entry carries `sha256` (`--unpack` hash of the tag archive), `vendorHash` and `go`.
- `go` must name an existing [go](../go/EGM.md) version.

## Side Effects
- Build time only: fixed-output fetches of the tagged source and Go module dependencies. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#gotestsum.default` (or `.#gotestsum.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
