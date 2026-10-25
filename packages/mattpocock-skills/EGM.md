# mattpocock-skills

## Overview

Matt Pocock's agent skills packaged as a Claude Code plugin directory via `toolboxLib.buildSkillBundle`, restricted to upstream's manifest.
Source: `default.nix` (builder) and `data.json` (version metadata).

## Interface

- Registry entry `toolbox.mattpocock-skills` (stamp `kind = "skill-bundle"`): `versions` = 1.1.0, 1.2.3, 1.3.1; `default` = `1.3.1`.
- Builder: `toolboxLib.buildSkillBundle { inherit pkgs; name = "mattpocock-skills"; dataPath = ./data.json; }`.
- Output: a plugin directory (`.claude-plugin/plugin.json` + selected `skills/<name>/`), plus `passthru.skills`, a flattened one-folder-per-skill view.
- `_meta.fromClaudePlugin` = `true`.

## Invariants

- Each version entry must carry `owner`, `repo`, `rev` (a commit, not a tag) and `sha256` (`--unpack` hash of that commit's tarball).
- Skill selection runs in the build sandbox with `jq` over the pinned source; nothing is selected at evaluation time (no IFD).
- Only skills listed in upstream's `.claude-plugin/plugin.json` `skills` array are shipped; repo extras (`skills/deprecated`, `skills/in-progress`, ...) are dropped and the upstream manifest is shipped with its `skills` array rewritten.

## Side Effects

- Fixed-output fetch of the pinned `mattpocock/skills` commit at build time only; evaluation is offline.
- No hooks or executables are installed; consumers load the skills into Claude Code.

## Verification

Run from the repository root:

```bash
nix build --no-link .#mattpocock-skills.default
printf '%s' "$PWD" > .devenv-root
nix flake check --impure --override-input devenv-root "file+file://$PWD/.devenv-root"
```

The flake exposes only x86_64-linux, aarch64-linux and aarch64-darwin; x86_64-darwin entries in platform tables are carried but not built.
