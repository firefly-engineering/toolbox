{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  components = {
    buck2 = toolbox.buck2;
    reindeer = toolbox.reindeer;
  };

  mkToolchain = version: versionData:
    pkgs.symlinkJoin {
      name = "buck2-toolchain-${version}";
      paths = lib.mapAttrsToList (name: ver:
        components.${name}.versions.${ver}
      ) (lib.filterAttrs (n: _: builtins.hasAttr n components) versionData);
    };
in
{
  versions = builtins.mapAttrs mkToolchain versions;
  default = meta.default;
}
