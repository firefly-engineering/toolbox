# ponytail-skills

## Overview

Ponytail agent skills (`ponytail` mode plus audit/review/debt/gain/help) packaged as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`, without upstream's hooks.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.ponytail-skills` (stamp `kind = "skill-bundle"`): `versions` = 4.10.3, 5.1.0; `default` = `5.1.0`.
- Builder: `toolboxLib.buildSkillBundle { inherit pkgs; name = "ponytail-skills"; dataPath = ./data.json; }`.
- Output: a plugin directory (`.claude-plugin/plugin.json` + selected `skills/<name>/`), plus `passthru.skills`, a flattened one-folder-per-skill view.
- `_meta.fromClaudePlugin`: absent, so it defaults to `false`.

## Invariants

- Each version entry must carry `owner`, `repo`, `rev` (a commit, not a tag) and `sha256` (`--unpack` hash of that commit's tarball).
- Skill selection runs in the build sandbox with `jq` over the pinned source; nothing is selected at evaluation time (no IFD).
- `fromClaudePlugin` is false: every `skills/*/SKILL.md` is discovered and a skills-only `{ name, skills }` manifest is synthesized, so upstream's node auto-activation hooks are deliberately not shipped.
- `rev` is the commit the release tag points at.

## Side Effects

- Fixed-output fetch of the pinned `DietrichGebert/ponytail` commit at build time only; evaluation is offline.
- No hooks or executables are installed; consumers load the skills into Claude Code.

## Verification

Run from the repository root:

```bash
nix build --no-link .#ponytail-skills.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
