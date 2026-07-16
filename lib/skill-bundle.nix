# Support code for packaging Claude Code "skill bundles".
#
# A skill bundle is a pinned upstream source (a git repo of Claude skills,
# typically shipping a `.claude-plugin/plugin.json`) assembled into a Claude
# Code *plugin directory*: `.claude-plugin/plugin.json` + the selected skill
# directories at their upstream-relative paths.
#
# Downstream consumers wire the result into home-manager's claude-code module:
#   programs.claude-code.plugins = [ pkg ];              # the whole bundle
#   programs.claude-code.skills  = "${pkg.skills}";      # flattened view
# where `pkg.skills` (a passthru) is a one-folder-per-skill directory, the shape
# the `skills` path option expects (it cannot consume upstream category nesting).
#
# Reproducibility: skill *selection* is performed inside the build sandbox with
# `jq` (a real JSON parser) reading the upstream manifest — never at Nix eval
# time. There is no import-from-derivation; the output is a pure function of the
# pinned source hash. `fromClaudePlugin` restricts the bundle to exactly the
# skills the upstream manifest advertises, dropping anything else in the repo
# (deprecated/, in-progress/, …).
{ lib, readData }:

{
  # buildSkillBundle { pkgs, name, dataPath } -> { versions; default; }
  #
  # data.json schema (per version, unless noted):
  #   owner/repo/rev/sha256  fetchFromGitHub source pin (rev is a commit)
  #   fromClaudePlugin       bool; restrict to the manifest's `skills` list
  #                          (defaults from `_meta.fromClaudePlugin`, else false)
  #   pluginJsonPath         manifest path (default ".claude-plugin/plugin.json")
  #   select                 optional allowlist of skill basenames to keep
  #   exclude                optional denylist of skill basenames to drop
  buildSkillBundle = { pkgs, name, dataPath }:
    let
      inherit (readData dataPath) meta versions;

      buildOne = version: versionData:
        let
          src = pkgs.fetchFromGitHub {
            inherit (versionData) owner repo rev;
            hash = versionData.sha256;
          };

          fromPlugin = versionData.fromClaudePlugin or meta.fromClaudePlugin or false;
          pluginJsonPath = versionData.pluginJsonPath or ".claude-plugin/plugin.json";
          selectJson = builtins.toJSON (versionData.select or [ ]);
          excludeJson = builtins.toJSON (versionData.exclude or [ ]);

          # The plugin directory: manifest + selected skill dirs, nesting preserved
          # so the manifest's relative `./skills/...` paths keep resolving.
          bundle = pkgs.runCommand "${name}-${version}"
            {
              inherit src;
              nativeBuildInputs = [ pkgs.jq ];
            }
            (''
              mkdir -p "$out/.claude-plugin" "$out/skills"

              # 1. Candidate skill paths ("./skills/<...>") as a JSON array.
            ''
            + (if fromPlugin then ''
              candidates=$(jq -c '.skills' "$src/${pluginJsonPath}")
            '' else ''
              candidates=$(cd "$src" && find skills -type f -name SKILL.md \
                -exec dirname {} \; | sort | sed 's|^|./|' | jq -R . | jq -sc .)
            '')
            + ''
              # 2. Apply optional select/exclude filters, matched by basename.
              selected=$(jq -cn \
                --argjson c "$candidates" \
                --argjson sel '${selectJson}' \
                --argjson exc '${excludeJson}' '
                  $c
                  | map({ p: ., b: (split("/") | last) })
                  | map(select(($sel | length) == 0 or (.b as $b | $sel | index($b))))
                  | map(select((.b as $b | $exc | index($b)) | not))
                  | map(.p)
                ')

              # 3. Copy each selected skill dir, preserving its relative path.
              echo "$selected" | jq -r '.[]' | while read -r rel; do
                if [ ! -d "$src/$rel" ]; then
                  echo "skill '$rel' selected for ${name} ${version} is missing from source" >&2
                  exit 1
                fi
                mkdir -p "$(dirname "$out/$rel")"
                cp -R "$src/$rel" "$out/$rel"
              done

              # 4. Manifest: upstream's (skills rewritten to the selection) when
              #    filtering from the plugin, else a freshly synthesized one.
            ''
            + (if fromPlugin then ''
              base=$(cat "$src/${pluginJsonPath}")
            '' else ''
              base=${lib.escapeShellArg (builtins.toJSON { inherit name; })}
            '')
            + ''
              echo "$base" | jq --argjson skills "$selected" '.skills = $skills' \
                > "$out/.claude-plugin/plugin.json"
            '');

          # Flattened one-folder-per-skill view for `programs.claude-code.skills`.
          # Reads the bundle's own manifest so the selection is single-sourced.
          skills = pkgs.runCommand "${name}-${version}-skills"
            {
              inherit bundle;
              nativeBuildInputs = [ pkgs.jq ];
            }
            ''
              mkdir -p "$out"
              jq -r '.skills[]' "$bundle/.claude-plugin/plugin.json" | while read -r rel; do
                base=$(basename "$rel")
                if [ -e "$out/$base" ]; then
                  echo "skill name collision flattening ${name} ${version}: '$base'" >&2
                  exit 1
                fi
                cp -R "$bundle/$rel" "$out/$base"
              done
            '';
        in
        bundle.overrideAttrs (old: {
          passthru = (old.passthru or { }) // { inherit skills; };
        });
    in
    {
      versions = builtins.mapAttrs buildOne versions;
      default = meta.default;
    };
}
