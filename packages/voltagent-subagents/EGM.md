# voltagent-subagents

## Overview
Packages [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents), a catalog of Claude Code subagent definitions, so that no agent is active until chosen. Global agents are chosen in home-manager; per-project agents through the bundled `subagent-catalog` skill. The skill replaces upstream's `tools/subagent-catalog`, which fetches `README.md` from GitHub `main` at run time and can only display definitions.

## Interface
- `default.nix`: `toolboxLib.buildPackage` with one `default` builder. Stamp `kind = "package"`: the output is a plugin directory, but not a skill bundle, so `buildToolchain` would not merge its manifest.
- Output:
  - `agents/<name>.md`: every definition, flattened out of `categories/NN-<category>/`.
  - `catalog.json`: `[{ name, category, description, tools, model }]`, sorted by category then name; `category` is the directory name minus its `NN-` prefix.
  - `skills/subagent-catalog/`: `SKILL.md` (`./SKILL.md`) and the `subagent-catalog` script (`./subagent-catalog.sh` via `writeShellApplication`, with the catalog store path prepended).
  - `.claude-plugin/plugin.json`: `{ name, skills: [ "./skills/subagent-catalog" ] }`. It lists no agents, so installing the plugin enables none.
- `passthru.catalog` (`agents/` + `catalog.json` only) and `passthru.cli` (the script as a package).
- `subagent-catalog list [query] | show <name> | status | enable [-f] <name>... | disable <name>...`. It targets `<root>/.claude/agents/`, where root is `jj root`, else `git rev-parse --show-toplevel`, else the cwd.
- `data.json`: version `1.0.4` (default). Upstream has no tags or releases; the version is `metadata.version` of upstream's `.claude-plugin/marketplace.json` at the pinned commit. `_meta.releases` points at the commit log.
- Consuming from home-manager: see "With home-manager (Claude Code subagents)" in the [README](../../README.md).

## Invariants
- Each version entry carries `owner`, `repo`, `rev` (a full commit SHA) and `sha256` (`--unpack` hash of that commit's archive). On a bump, `rev` and the version must both move: read the version from `marketplace.json` at the new `rev`.
- Every `categories/*/*.md` except `README.md` is an agent. Upstream's per-category `plugin.json` `agents` lists are not used: they are hand-maintained and at `f2e2ea7` already miss `docs-drift-editor`.
- The build fails if a file's frontmatter `name` differs from its file name, or if two categories ship the same name. Frontmatter is parsed with `yq` in the sandbox.
- `enable` copies, never symlinks: copies survive GC and can be committed. It refuses to overwrite a differing copy without `-f`; `disable` only deletes a copy identical to the packaged one. Both protect local edits.

## Side Effects
- Build time only: fixed-output GitHub archive fetch.
- Runtime (the script): `enable` creates `<root>/.claude/agents/` and writes files there; `disable` deletes files there. Nothing else, no network.

## Verification
- Run: `nix build --no-link .#voltagent-subagents.default`
- Run: `jq length result/catalog.json` equals `ls result/agents | wc -l` (165 at `1.0.4`).
- Run: in a scratch git repo, `<out>/skills/subagent-catalog/subagent-catalog enable code-reviewer`, then `status`, then `disable code-reviewer`.
- Run: `nix flake check` (registry gate; pass the `devenv-root` override described in the Verification Checklist of `AGENTS.md`)
