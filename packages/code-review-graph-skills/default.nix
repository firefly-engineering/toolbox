{ pkgs, lib, toolbox, toolboxLib }:

# code-review-graph's agent skills (`skills/*/SKILL.md`: review-pr,
# review-changes, explore-codebase, …), packaged as a Claude Code plugin
# directory. They call the MCP tools of `code-review-graph serve`, so register
# that server alongside them.
#
# The source pin is read from `packages/code-review-graph/data.json`, the file
# that builds the server, so the skills never describe a different version.
#
# Upstream ships no `.claude-plugin/plugin.json`, so `fromClaudePlugin` stays
# false: the builder discovers `skills/*/SKILL.md` and synthesizes the manifest.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "code-review-graph-skills";
  dataPath = ../code-review-graph/data.json;
}
