{ pkgs, lib, toolbox, toolboxLib }:

# Matt Pocock's agent skills, packaged as a Claude Code plugin directory.
# `fromClaudePlugin` (set in data.json) restricts the bundle to exactly the
# skills listed in upstream's `.claude-plugin/plugin.json`, so repo extras
# (skills/deprecated, skills/in-progress, …) are excluded.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "mattpocock-skills";
  dataPath = ./data.json;
}
