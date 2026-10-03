{ pkgs, lib, toolbox, toolboxLib }:

# Ponytail's agent skills (`skills/*/`), packaged as a Claude Code plugin
# directory: the `ponytail` mode (simplest solution that works — YAGNI, stdlib
# first) plus its audit/review/debt/gain/help companions.
#
# Upstream's `.claude-plugin/plugin.json` lists no `skills` (Claude Code
# auto-discovers `skills/`) and wires node hooks that auto-activate the mode
# every session. `fromClaudePlugin` stays false: the builder discovers
# `skills/*/SKILL.md` and synthesizes a skills-only manifest, so the hooks are
# deliberately not shipped — invoke `/ponytail` explicitly.
#
# The pin is the commit the release tag points at.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "ponytail-skills";
  dataPath = ./data.json;
}
