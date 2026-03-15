{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  components = {
    rust = toolbox.rust;
    rust-analyzer = toolbox.rust-analyzer;
    cargo-edit = toolbox.cargo-edit;
  };

  mkToolchain = version: versionData:
    pkgs.symlinkJoin {
      name = "rust-toolchain-${version}";
      paths = lib.mapAttrsToList (name: ver:
        components.${name}.versions.${ver}
      ) (lib.filterAttrs (n: _: builtins.hasAttr n components) versionData);
    };
in
{
  versions = builtins.mapAttrs mkToolchain versions;
  default = meta.default;
}
