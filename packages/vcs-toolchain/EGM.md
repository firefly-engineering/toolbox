# vcs-toolchain

## Overview

Bundles version-control tooling: Jujutsu and its UIs, git and GitHub CLIs, diff viewers and review tools. A toolchain is a meta-package: each version is a `symlinkJoin` of pinned toolbox packages, with no build logic of its own.

## Interface

- `default.nix`: `toolboxLib.buildToolchain { name = "vcs-toolchain"; dataPath = ./data.json; }`.
- `data.json`: versions `1`..`17`, `_meta.default` = `17` (`jj 0.46.0`, `jjui 0.10.11`, `jj-hunk 0.5.1`, `hunk 0.23.0`, `git 2.55.0`, `git-lfs 3.8.0`, `gh 2.101.0`, `difftastic 0.70.0`, `delta 0.20.1`, `gh-aw 0.88.7`, `gh-stack 0.2.1`, `entire 0.11.4`, `tuicr 0.27.0`). No `_meta.releases`.
- Components (version `17`): [jj](../jj/EGM.md), [jjui](../jjui/EGM.md), [jj-hunk](../jj-hunk/EGM.md), [hunk](../hunk/EGM.md), [git](../git/EGM.md), [git-lfs](../git-lfs/EGM.md), [gh](../gh/EGM.md), [difftastic](../difftastic/EGM.md), [delta](../delta/EGM.md), [gh-aw](../gh-aw/EGM.md), [gh-stack](../gh-stack/EGM.md), [entire](../entire/EGM.md), [tuicr](../tuicr/EGM.md). Older versions carry subsets (e.g. `tuicr` from `10`, `entire` from `9`, `hunk` from `6`, `jj-hunk` from `5`, `git-lfs` from `4`).
- Bundles no skill bundle (`tuicr` is the binary, not [tuicr-skills](../tuicr-skills/EGM.md)), so the plain `symlinkJoin` path applies.

## Invariants

- Every component key must be a toolbox package name, and every pin a version that package defines; `nix flake check` fails on a pin resolving to nothing.
- Versions are immutable: a component bump adds a new toolchain version rather than editing an existing one.
- Available only on systems where every component is available (`buildToolchain` intersects their platforms).
- The registry stamp has `kind = "toolchain"` and `components` = the per-version pins.

## Side Effects

- None of its own; building it builds or substitutes its components.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#vcs-toolchain.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
