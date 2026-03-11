{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "buck2-toolchain-1";
      paths = [
        toolbox.buck2.versions.${toolbox.buck2.default}
        toolbox.reindeer.versions.${toolbox.reindeer.default}
      ];
    };
  };
  default = "1";
}
