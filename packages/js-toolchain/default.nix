{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  components = {
    nodejs = toolbox.nodejs;
    biome = toolbox.biome;
  };

  mkToolchain = version: versionData:
    pkgs.symlinkJoin {
      name = "js-toolchain-${version}";
      paths = lib.mapAttrsToList (name: ver:
        components.${name}.versions.${ver}
      ) (lib.filterAttrs (n: _: builtins.hasAttr n components) versionData);
    };
in
{
  versions = builtins.mapAttrs mkToolchain versions;
  default = meta.default;
}
