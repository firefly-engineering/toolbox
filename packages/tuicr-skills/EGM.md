# tuicr-skills

## Overview

Packages tuicr's agent skill (`skills/tuicr/`: `SKILL.md` plus the tmux/Zellij/Herdr wrapper scripts) as a Claude Code plugin directory. It has no `data.json` of its own: its source pin is read from [tuicr](../tuicr/EGM.md)'s `data.json`, so the skill always matches the tuicr binary of the same version.

## Interface

- `default.nix`: `toolboxLib.buildSkillBundle { name = "tuicr-skills"; dataPath = ../tuicr/data.json; }`.
- Versions and `_meta.default`: exactly those of `packages/tuicr/data.json` (currently default `0.27.0`).
- Output: `.claude-plugin/plugin.json` (a synthesized `{ name, skills }` manifest) and `skills/tuicr/`; `passthru.skills` is the flattened one-folder-per-skill view.
- Platforms: wherever `buildSkillBundle` is available (no binaries).

## Invariants

- Reads `owner`, `repo`, `rev`, `sha256` from each tuicr version entry (`fetchFromGitHub`); bumping tuicr bumps this bundle with no second edit.
- Upstream ships no `.claude-plugin/plugin.json`, so `fromClaudePlugin` stays false: every directory under `skills/` that holds a `SKILL.md`, at any depth (`find skills -name SKILL.md`), is included. Skill selection runs in the build sandbox with `jq`, not at eval time.
- Registry stamp `kind = "skill-bundle"`.

## Side Effects

- Build time only: fixed-output fetch of the tuicr source.

## Verification

Run from the repository root:

- Run: `nix build --no-link .#tuicr-skills.default`
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` (after `printf '%s' "$PWD" > .devenv-root`; see `AGENTS.md`)
