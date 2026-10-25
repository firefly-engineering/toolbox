# beadwork

## Overview
Packages beadwork (`bw`), the git-native work tracker this repository itself uses, built from the tagged source `jallum/beadwork` with `toolboxLib.buildGoPackage`. Versions from 0.12.3 apply a vendored patch from the `sigma/beadwork` `tui` branch that adds a `bw-tui` binary.

## Interface
- `default.nix`: `builders.default = toolboxLib.buildGoPackage { pname = "beadwork"; subPackages = [ "cmd/bw" ]; ... }`. Its `extraArgs` sets `patches = toolboxLib.resolvePatches ./. versionData` and `nativeBuildInputs = [ pkgs.git ]`.
- Versions: `0.13.3` (`_meta.default`), `0.13.0`, `0.12.3`, `0.11.7`, `0.11.6`.
- Installs `$out/bin/bw` (`meta.mainProgram`); patched versions (0.12.3+) also install `$out/bin/bw-tui` via `versionData.subPackages = [ "cmd/bw" "cmd/bw-tui" ]`.
- Cross-package dep: `toolbox.go.versions.${versionData.go}` (Go 1.26.1; 1.25.7 for 0.11.6).
- `patches/`: vendored patch files. They add Go sources (`cmd/bw-tui/*.go`) and a `.claude/skills/sync-tui/SKILL.md`.
  - `patches/sigma-tui-0.12.3.patch`
  - `patches/sigma-tui-0.13.0.patch`
  - `patches/sigma-tui-0.13.3.patch`

## Invariants
- Each version entry needs `sha256`, `vendorHash` and `go`; optional `subPackages` overrides the builder default.
- Each `patches[].file` must exist on disk and be named for its base version; `patches[].source` (owner/repo/branch/commit) is regeneration metadata only, managed by the `/manage-patches` skill.
- `vendorHash` covers the patched module graph, so refreshing a patch may change it.
- Tests are skipped (`doCheck = false`, set by `buildGoPackage`).

## Side Effects
- Build time only: fixed-output fetches of the source tarball and Go module vendor tree.

## Verification
- Run: `nix build --no-link .#beadwork.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
