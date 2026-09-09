{ pkgs, lib, toolbox, toolboxLib }:

# Herdr's agent skill (`skills/herdr/`), packaged as a Claude Code plugin
# directory. It teaches an agent to drive Herdr from inside a Herdr-managed
# pane — inspecting workspaces, tabs, panes and neighbouring agents, and
# splitting panes without stealing focus. See https://herdr.dev/docs/agent-skill/
#
# Upstream ships no `.claude-plugin/plugin.json`, so `fromClaudePlugin` stays
# false: the builder discovers `skills/*/SKILL.md` and synthesizes the manifest.
#
# The pin is a commit, not a tag: the skill is a file in the herdr repo, so it
# moves independently of herdr's own release cadence.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "herdr-skills";
  dataPath = ./data.json;
}
