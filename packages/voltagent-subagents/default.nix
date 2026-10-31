{ pkgs, lib, toolbox, toolboxLib }:

# VoltAgent's catalog of Claude Code subagents, packaged so that *none* of them
# is active by default:
#
#   agents/<name>.md        every definition, flat (upstream nests them under
#                           categories/NN-<category>/)
#   catalog.json            [{ name, category, description, tools, model }]
#   skills/subagent-catalog the skill that copies chosen agents into a
#                           project's .claude/agents/
#   .claude-plugin/plugin.json  lists that skill only, never the agents, so
#                           installing the plugin enables no agent.
#
# Global agents are picked one by one in home-manager from `agents/`; see
# EGM.md. Every `categories/*/*.md` but the READMEs is an agent: upstream's
# per-category plugin.json files are hand-maintained and already miss one
# (docs-drift-editor), so they are not the source of truth here.
let
  builders.default = version: versionData:
    let
      src = pkgs.fetchFromGitHub {
        inherit (versionData) owner repo rev;
        hash = versionData.sha256;
      };

      # Frontmatter is parsed with yq (a real YAML parser), in the sandbox.
      catalog = pkgs.runCommand "voltagent-subagents-catalog-${version}"
        {
          inherit src;
          nativeBuildInputs = [ pkgs.yq-go pkgs.jq ];
        }
        ''
          mkdir -p "$out/agents" entries
          for f in "$src"/categories/*/*.md; do
            file=$(basename "$f" .md)
            [ "$file" = README ] && continue
            dir=$(basename "$(dirname "$f")")
            name=$(yq --front-matter=extract '.name' "$f")
            if [ "$name" != "$file" ]; then
              echo "$f: frontmatter name '$name' does not match its file name" >&2
              exit 1
            fi
            if [ -e "$out/agents/$name.md" ]; then
              echo "agent name collision: '$name'" >&2
              exit 1
            fi
            cp "$f" "$out/agents/$name.md"
            yq --front-matter=extract -o json \
              '{ "name": .name, "description": .description, "tools": .tools, "model": .model }' "$f" \
              | jq --arg c "''${dir#*-}" '. + { category: $c }' > "entries/$name.json"
          done
          jq -s 'sort_by(.category, .name)' entries/*.json > "$out/catalog.json"
        '';

      cli = pkgs.writeShellApplication {
        name = "subagent-catalog";
        runtimeInputs = [ pkgs.jq pkgs.diffutils pkgs.coreutils ];
        text = ''
          catalog=${catalog}
        '' + builtins.readFile ./subagent-catalog.sh;
      };
    in
    pkgs.runCommand "voltagent-subagents-${version}"
      {
        passthru = { inherit catalog cli; };
        meta = with lib; {
          description = "VoltAgent's Claude Code subagent catalog, with a skill to enable agents per project";
          homepage = "https://github.com/VoltAgent/awesome-claude-code-subagents";
          license = licenses.mit;
        };
      }
      ''
        cp -R ${catalog}/. "$out"
        chmod u+w "$out"
        mkdir -p "$out/.claude-plugin" "$out/skills/subagent-catalog"
        cp ${./SKILL.md} "$out/skills/subagent-catalog/SKILL.md"
        ln -s ${cli}/bin/subagent-catalog "$out/skills/subagent-catalog/subagent-catalog"
        echo '{ "name": "voltagent-subagents", "skills": [ "./skills/subagent-catalog" ] }' \
          > "$out/.claude-plugin/plugin.json"
      '';
in
toolboxLib.buildPackage { name = "voltagent-subagents"; dataPath = ./data.json; inherit builders; }
