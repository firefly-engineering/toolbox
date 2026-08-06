{ pkgs, lib, toolbox, toolboxLib }:

# tuicr's agent skill (`skills/tuicr/`: SKILL.md + the tmux/Zellij/Herdr wrapper
# scripts), packaged as a Claude Code plugin directory.
#
# The source pin is read from `packages/tuicr/data.json` — the *same file*, and
# the same `owner`/`repo`/`rev`/`sha256` fields, that build the tuicr binary.
# There is no second place to bump, so the skill can never describe a different
# tuicr than the one installed alongside it.
#
# Upstream ships no `.claude-plugin/plugin.json`, so `fromClaudePlugin` stays
# false: the builder discovers `skills/*/SKILL.md` and synthesizes the manifest.
#
# The `data.json` sitting next to this file holds *no version data* — it is a
# `_meta.dataFrom` pointer read only by the docs generator, which discovers
# packages by walking `packages/*/data.json`. Nix reads the shared file below;
# the pointer adds no second place to bump. See docs/adr/0002.
toolboxLib.buildSkillBundle {
  inherit pkgs;
  name = "tuicr-skills";
  dataPath = ../tuicr/data.json;
}
