{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  components = {
    python = toolbox.python;
    uv = toolbox.uv;
    ruff = toolbox.ruff;
  };

  mkToolchain = version: versionData:
    pkgs.symlinkJoin {
      name = "python-toolchain-${version}";
      paths = lib.mapAttrsToList (name: ver:
        components.${name}.versions.${ver}
      ) (lib.filterAttrs (n: _: builtins.hasAttr n components) versionData);
    };
in
{
  versions = builtins.mapAttrs mkToolchain versions;
  default = meta.default;
}
