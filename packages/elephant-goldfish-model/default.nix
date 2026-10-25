{ pkgs, lib, toolbox, toolboxLib }:

# The Elephant-Goldfish Model (EGM) plugin, shipped as upstream's whole tree.
#
# Not a `buildSkillBundle`: EGM's skills read `agents/`, `resources/` and
# `docs/` at run time, and its Claude manifest wires subagents and a
# PreToolUse hook. Upstream warns that skill-only installs break it, so the
# pinned checkout *is* the plugin directory. It carries every harness's
# manifest (`.claude-plugin/`, `.codex-plugin/`, root `plugin.json`).
#
# Upstream has no tags and does not bump the manifest `version`, so versions
# are keyed by commit date.
let
  builders = {
    default = version: versionData:
      pkgs.fetchFromGitHub {
        owner = "google";
        repo = "elephant-goldfish-model";
        rev = versionData.rev;
        hash = versionData.sha256;
        passthru = { inherit version; };
      };
  };
in
toolboxLib.buildPackage { name = "elephant-goldfish-model"; dataPath = ./data.json; inherit builders; }
