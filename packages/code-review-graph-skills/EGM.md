# code-review-graph-skills

## Overview
Skill bundle packaging code-review-graph's agent skills (`skills/*/SKILL.md`: review-pr, review-changes, explore-codebase, and others) as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`. It has no `data.json` of its own.

## Interface
- `default.nix`: `toolboxLib.buildSkillBundle { name = "code-review-graph-skills"; dataPath = ../code-review-graph/data.json; }`; stamp `kind = "skill-bundle"`.
- Versions: those of [code-review-graph](../code-review-graph/EGM.md); currently `2.3.9` (default).
- Output: `.claude-plugin/plugin.json` (synthesized `{ name, skills }`) plus the skill directories; `passthru.skills` is the flattened view.
- The skills call the MCP tools of `code-review-graph serve`; register that server alongside them.

## Invariants
- The source pin (`owner`, `repo`, `rev`, `sha256`) comes from `packages/code-review-graph/data.json`, so skills and server never describe different versions.
- `fromClaudePlugin` is false: upstream ships no `.claude-plugin/plugin.json`, so every `skills/*` directory with a `SKILL.md` is included.

## Side Effects
- Build time only: fixed-output fetch of the pinned GitHub commit.

## Verification
- Run: `nix build --no-link .#code-review-graph-skills.default`
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
