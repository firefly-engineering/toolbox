# caveman-skills

## Overview
Skill bundle packaging Caveman's self-contained agent skills as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`: the voice modes, terse commit and review skills, and the help card.

## Interface
- `default.nix`: `toolboxLib.buildSkillBundle { name = "caveman-skills"; dataPath = ./data.json; }`; stamp `kind = "skill-bundle"`.
- Versions: `3.2.0` (`_meta.default`), `3.1.0`; each pins `JuliusBrussee/caveman` at the commit its `v<version>` tag points at.
- Selected skills: `caveman`, `ultracave`, `megacave`, `caveman-commit`, `caveman-review`, `caveman-help`.
- Output: `.claude-plugin/plugin.json` (synthesized `{ name, skills }`) plus the skill directories; `passthru.skills` is the flattened one-folder-per-skill view.

## Invariants
- Each version entry needs `owner`, `repo`, `rev` (commit) and `sha256`, plus the `select` allowlist.
- `fromClaudePlugin` is false: upstream's manifest lists no `skills`.
- Skills needing subagents, hooks, bundled scripts, the `caveman` CLI or a Caveman Cloud account are excluded on purpose; the auto-activation hooks are not shipped.
- Selection runs in the build sandbox with `jq`, never at eval time.
- Every `select` name must match a skill in the source. If upstream renames or drops one, the build fails and names it.

## Side Effects
- Build time only: fixed-output fetch of the pinned GitHub commit.

## Verification
- Run: `nix build --no-link .#caveman-skills.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
