{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "js-toolchain-1";
      paths = [
        toolbox.nodejs.versions.${toolbox.nodejs.default}
        toolbox.biome.versions.${toolbox.biome.default}
      ];
    };
  };
  default = "1";
}
