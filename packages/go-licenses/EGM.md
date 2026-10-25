# go-licenses

## Overview
Builds [go-licenses](https://github.com/google/go-licenses), which reports the licenses of a Go package and its dependencies, from its tagged source via `toolboxLib.buildGoPackage` (`lib/go-package.nix`).

## Interface
- `default.nix`: a local `mkBuilder extraArgs` wraps `toolboxLib.buildGoPackage { owner = "google"; repo = "go-licenses"; ... }` (default `rev = "v<version>"`, `subPackages = [ "." ]`).
- Builders: `default` (no extra args) and `legacy` (`proxyVendor = true`).
- Installs `$out/bin/go-licenses` (`meta.mainProgram = "go-licenses"`).
- `data.json`: versions `2.0.1` (default, builder `default`), `1.6.0` (builder `legacy`); both pin `go = "1.26.2"`.
- Cross-package dependency: `toolbox.go.versions.${versionData.go}` ([go](../go/EGM.md)).

## Invariants
- Each version entry carries `sha256` (`--unpack` hash of the tag archive), `vendorHash`, and `go`; `builder` is optional.
- `vendorHash` depends on the builder: a `legacy` (`proxyVendor`) entry hashes the module proxy cache, not a `vendor/` tree, so moving a version between builders changes its hash.
- `go` must name an existing [go](../go/EGM.md) version.

## Side Effects
- Build time only: fixed-output fetches of the tagged source and the Go module dependencies. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#go-licenses.default` (or `.#go-licenses.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
