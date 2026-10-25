# gopls

## Overview
Builds [gopls](https://pkg.go.dev/golang.org/x/tools/gopls), the official Go language server, from the `golang/tools` monorepo via `toolboxLib.buildGoPackage`.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildGoPackage { owner = "golang"; repo = "tools"; rev = { version }: "gopls/v${version}"; extraArgs.sourceRoot = "source/gopls"; ... }`, passed to `toolboxLib.buildPackage`.
- Builds the `gopls` sub-module (its own `go.mod`) with the default `subPackages = [ "." ]`.
- Installs `$out/bin/gopls` (`meta.mainProgram = "gopls"`).
- `data.json`: versions `0.24.0` (default, go 1.27.2), `0.23.0` (go 1.26.4), `0.22.0` (go 1.26.4), `0.21.1` (go 1.26.0).
- Cross-package dependency: `toolbox.go.versions.${versionData.go}` ([go](../go/EGM.md)). Consumed by [go-toolchain](../go-toolchain/EGM.md).

## Invariants
- Each version entry carries `sha256` (`--unpack` hash of the `gopls/v<version>` tag archive of `golang/tools`), `vendorHash` and `go`.
- The tag is `gopls/v<version>`, not `v<version>`; prefetch URLs must use it.
- The pinned `go` must satisfy the `go` directive in that gopls release's `go.mod`.

## Side Effects
- Build time only: fixed-output fetches of the tagged source and Go module dependencies. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#gopls.default` (or `.#gopls.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
