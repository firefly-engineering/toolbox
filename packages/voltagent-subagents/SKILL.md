---
name: subagent-catalog
description: Find subagents in the VoltAgent catalog and enable or disable them for the current project, by copying their packaged definitions into the project's .claude/agents/. Use when the user wants to browse, search, show, add, enable, activate, remove or refresh a subagent for this project.
---

# Subagent catalog

The catalog is a pinned, installed package: no network access, no cache. Run
`<this skill's base directory>/subagent-catalog` from inside the project:

| Command | Does |
|---|---|
| `subagent-catalog list [query]` | `category<TAB>name<TAB>description` rows; query is a case-insensitive substring of any field |
| `subagent-catalog show <name>` | print the full definition |
| `subagent-catalog status` | catalog agents already in this project: `current` or `modified` |
| `subagent-catalog enable <name>...` | copy into `<project root>/.claude/agents/<name>.md` |
| `subagent-catalog disable <name>...` | delete those copies, only if unchanged from the package |

The project root is `jj root`, else `git rev-parse --show-toplevel`, else the
current directory.

## Workflow

1. Search with `list <query>`. Prefer the narrowest query; show the user the
   matching names and descriptions, not the raw rows.
2. Confirm which agents to enable before running `enable`.
3. `enable` refuses to overwrite a copy that differs from the package. That copy
   is either a local edit or an older package version. Show the user
   `diff <project>/.claude/agents/<name>.md <(subagent-catalog show <name>)`, and
   rerun with `enable -f <name>` only if they agree.
4. Tell the user that new agents load at the next session start (or after
   `/agents`), and that `.claude/agents/` is theirs to commit or ignore.

Never edit files in the catalog: they live in the Nix store. To customise an
agent, enable it, then edit the project copy.
