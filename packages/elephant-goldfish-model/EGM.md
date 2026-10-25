# elephant-goldfish-model

## Overview
Ships the [Elephant-Goldfish Model](https://github.com/google/elephant-goldfish-model) agent plugin as upstream's whole pinned source tree. Deliberately not a `buildSkillBundle`: EGM skills read `agents/`, `resources/` and `docs/` at run time and its Claude manifest wires subagents and a PreToolUse hook, so the checkout itself is the plugin directory (it carries `.claude-plugin/`, `.codex-plugin/` and a root `plugin.json`).

## Interface
- `default.nix`: `builders.default` returns `pkgs.fetchFromGitHub { owner = "google"; repo = "elephant-goldfish-model"; rev = versionData.rev; ... }` directly (the derivation is the fetched tree), passed to `toolboxLib.buildPackage`.
- Store path name: `elephant-goldfish-model-<version>` (it appears in `--plugin-dir` flags).
- `passthru.version` = the version key.
- No binaries; consumers point their harness at the store path as a plugin directory.
- `data.json`: version `2026-10-24` (default); `_meta.releases` = upstream `commits/main`.
- No cross-package dependencies.

## Invariants
- Upstream has no tags and does not bump its manifest `version`, so version keys are commit dates (`YYYY-MM-DD`).
- Each entry carries `rev` (a full commit SHA) and `sha256` (`--unpack` hash of that commit's archive).
- The output must stay the unmodified upstream tree: no skill selection or manifest rewriting.

## Side Effects
- Build time only: fixed-output GitHub archive fetch. At run time the plugin may register hooks and subagents in the consuming harness; that is upstream behaviour, not introduced by this package.

## Verification
- Run: `nix build .#elephant-goldfish-model.default` (or `.#elephant-goldfish-model.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
