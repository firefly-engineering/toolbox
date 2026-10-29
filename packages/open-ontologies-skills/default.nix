{ pkgs, lib, toolbox, toolboxLib }:

# open-ontologies' agent skill (`skills/ontology-engineering/`), packaged as a
# Claude Code plugin directory. It drives the MCP tools of
# `open-ontologies serve` (stdio), so register that server alongside it.
#
# The source pin is read from `packages/open-ontologies/data.json`, the file
# that pins the server, so the skill never describes a different version.
#
# Upstream's `.claude-plugin/plugin.json` lists no `skills`, so
# `fromClaudePlugin` stays false: the builder discovers `skills/*/SKILL.md` and
# synthesizes the manifest. The root `SKILL.md` is a registry listing, not part
# of the plugin, and is left out.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "open-ontologies-skills";
  dataPath = ../open-ontologies/data.json;
}
