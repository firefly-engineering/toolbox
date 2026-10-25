# beads-viewer

## Overview
Packages beads_viewer (`bv`), a terminal UI for the Beads issue tracker, built from the tagged source `Dicklesworthstone/beads_viewer` with `toolboxLib.buildGoPackage`. Marked inactive (`_meta.inactive = true`).

## Interface
- `default.nix`: `builders.default = toolboxLib.buildGoPackage { pname = "beads-viewer"; subPackages = [ "cmd/bv" ]; ... }`.
- Versions: `0.15.2` (`_meta.default`, Go 1.26.1), `0.14.4` (Go 1.26.0).
- Installs `$out/bin/bv` (`meta.mainProgram`).
- Cross-package dep: `toolbox.go.versions.${versionData.go}`.
- `ldflags` stamps `github.com/Dicklesworthstone/beads_viewer/pkg/version.Version=v<version>`.

## Invariants
- Each version entry needs `sha256`, `vendorHash` and `go`. Both current entries set `vendorHash` to `null` (upstream vendors its modules in-tree).
- `postPatch` rewrites the `go` line in `go.mod` to the pinned Go's version; `GOTOOLCHAIN = "auto"`.
- Tests are skipped (`doCheck = false`, set by `buildGoPackage`).

## Side Effects
- Build time only: fixed-output fetch of the source tarball.

## Verification
- Run: `nix build --no-link .#beads-viewer.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
