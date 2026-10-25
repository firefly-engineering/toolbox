# herdr-skills

## Overview
Packages Herdr's agent skill (`skills/herdr/` in [herdrdev/herdr](https://github.com/herdrdev/herdr)) as a Claude Code plugin directory via `toolboxLib.buildSkillBundle` (`lib/skill-bundle.nix`). The skill teaches an agent to drive Herdr (workspaces, tabs, panes, neighbouring agents) from inside a Herdr-managed pane.

## Interface
- `default.nix`: `toolboxLib.buildSkillBundle { inherit pkgs; name = "herdr-skills"; dataPath = ./data.json; }`.
- Output: plugin directory with a synthesized `.claude-plugin/plugin.json` (`{ name, skills }`) and the discovered skill directories; `passthru.skills` is the flattened one-folder-per-skill view.
- Registry stamp `kind = "skill-bundle"`.
- `data.json`: versions `0.9.3` (default, rev `7b116c05`), `0.9.0` (rev `b99002ac`); `_meta.releases` = herdr GitHub releases.
- No cross-package dependencies.

## Invariants
- Each version entry carries `owner`, `repo`, `rev` (a full commit SHA, not a tag) and `sha256` (`--unpack` hash of that commit's archive).
- `fromClaudePlugin` is unset (false): upstream ships no `.claude-plugin/plugin.json`, so every directory under `skills/` that holds a `SKILL.md`, at any depth (`find skills -name SKILL.md`), is included and the manifest is synthesized.
- Skill selection runs inside the build sandbox with `jq`, never at evaluation time.

## Side Effects
- Build time only: fixed-output GitHub archive fetch. No runtime side effects introduced by the package.

## Verification
- Run: `nix build .#herdr-skills.default` (or `.#herdr-skills.<version_underscored>` for a specific version)
- Run: `nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"` from the repo root after writing `$PWD` to `.devenv-root` (registry gate; see `AGENTS.md`, Verification Checklist)
