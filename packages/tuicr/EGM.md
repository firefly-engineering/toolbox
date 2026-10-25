# tuicr

## Overview

Packages [tuicr](https://github.com/agavra/tuicr), a code review TUI with vim keybindings. Recent versions are built from the tagged source tree so the pin is the same source [tuicr-skills](../tuicr-skills/EGM.md) bundles its skill from; the oldest version uses the prebuilt release.

## Interface

- `default.nix`: two builders passed to `toolboxLib.buildPackage { name = "tuicr"; }`:
  - `source`: hand-rolled `makeRustPlatform` + `buildRustPackage` with toolbox rust, fetching `fetchFromGitHub { owner; repo; rev; }` from the version entry.
  - `default`: `toolboxLib.buildPrebuiltBinary` on `https://github.com/agavra/tuicr/releases/download/v<version>/tuicr-<version>-<rust-triple>.tar.gz` (flat archive, `extraLibs = [ zlib ]` for libgit2).
- `data.json`: versions `0.27.0` (`_meta.default`), `0.26.0`, `0.25.0`, `0.21.0`, `0.20.0` use `builder = "source"` with rust `1.97.0`; `0.19.1` uses the prebuilt `default` builder.
- Output: `bin/tuicr`.
- Cross-package deps: `toolbox.rust.versions.<rust>` ([rust](../rust/EGM.md)) for the `source` builder. Consumed by [vcs-toolchain](../vcs-toolchain/EGM.md) and, through its `data.json`, by [tuicr-skills](../tuicr-skills/EGM.md).
- Platforms: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`. Linux source builds add `pkg-config`, `libxkbcommon`, `wayland`, `libxcb` (arboard clipboard backends).

## Invariants

- `source` entries need `owner`, `repo`, `rev`, `sha256` (`--unpack` hash of that rev), `cargoHash` and `rust`.
- `default` (prebuilt) entries need `<system>.sha256` for all four systems (raw `fetchurl` hash).
- Every entry must also carry `owner`/`repo`/`rev`/`sha256`, even the prebuilt `0.19.1`, because `tuicr-skills` builds a skill bundle from each version in this file.
- Tests are not run (`doCheck = false`).

## Side Effects

- Build time only: fixed-output fetches of the GitHub source and cargo vendor tree (`source`) or the release tarball (`default`).

## Verification

Run from the repository root:

- Run: `nix build --no-link .#tuicr.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
