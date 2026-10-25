# go

## Overview
Builds the [Go](https://go.dev) toolchain from the official source tarball, bootstrapped with nixpkgs' `pkgs.go`. It is the Go that every toolbox Go package compiles with (through `toolboxLib.buildGoPackage` or `buildGoModule.override { go = ...; }`).

## Interface
- `default.nix`: `builders.default` = `pkgs.stdenv.mkDerivation` with `fetchurl` of `https://go.dev/dl/go<version>.src.tar.gz`, built with `src/make.bash` and `GOROOT_BOOTSTRAP = ${pkgs.go}/share/go`, passed to `toolboxLib.buildPackage`.
- Output layout: full GOROOT at `$out/share/go`; `$out/bin/go` and `$out/bin/gofmt` symlink into it.
- `passthru`: `GOOS`, `GOARCH`, `CGO_ENABLED` copied from `pkgs.go`, the attributes `buildGoModule` expects of an overridden `go`.
- `meta.platforms` = `pkgs.go.meta.platforms`.
- `data.json`: versions `1.27.2` (default), `1.27.1`, `1.26.4`, `1.26.2`, `1.26.1`, `1.26.0`, `1.25.7`, `1.25.6`; `_meta.releases` = `https://go.dev/dl/`.
- Consumers: `toolbox.go.versions.${versionData.go}` in Go packages (e.g. [gopls](../gopls/EGM.md), [gotestsum](../gotestsum/EGM.md), [go-licenses](../go-licenses/EGM.md)) and the [go-toolchain](../go-toolchain/EGM.md) component pin.

## Invariants
- Each version entry carries only `sha256`, the raw-tarball `fetchurl` hash.
- Removing a version breaks any package whose `data.json` pins it via `go`; `nix flake check` catches dangling pins.
- The `passthru` attributes must stay, or `buildGoModule.override { inherit go; }` breaks for every Go package.
- The bootstrap compiler (`pkgs.go`) comes from the flake's nixpkgs input and must be new enough to bootstrap the target version.

## Side Effects
- Build time only: fixed-output `fetchurl` of the source tarball; the compile itself runs offline with `HOME=$TMPDIR`. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#go.default` (or `.#go.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
