{ pkgs, lib, toolbox, toolboxLib }:

# Caveman's self-contained agent skills, packaged as a Claude Code plugin
# directory: the voice modes (`caveman`, `ultracave`, `megacave`), terse
# commit messages and code review, and the help card.
#
# `select` keeps only skills that work as bare prompts. The rest of upstream's
# `skills/` is dropped on purpose:
#   - cavecrew, caveman-stats, caveman-compress need what a skill bundle does
#     not ship (subagent definitions, the node hooks, bundled python scripts);
#   - caveman-explore is a subagent prompt, not a skill: loaded inline it would
#     turn the main agent into a citations-only explorer;
#   - caveman-learn drives the `caveman` CLI, which toolbox does not package;
#   - caveman-setup/-discover/-evidence-review/-manage/-optimize need a
#     Caveman Cloud account;
#   - the "native practice" skills (investigate-first, surgical-patch, …) are
#     meant to be hook-routed and carry generic, collision-prone names.
#
# Upstream's `.claude-plugin/plugin.json` lists no `skills`, so
# `fromClaudePlugin` stays false and the manifest is synthesized; the hooks
# that auto-activate the mode are not shipped — invoke `/caveman` explicitly.
# The proxy is packaged separately as `caveman-proxy`.
#
# The pin is the commit the release tag points at.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "caveman-skills";
  dataPath = ./data.json;
}
