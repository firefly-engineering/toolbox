{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "solidity-toolchain-1";
      paths = [
        toolbox.solc.versions.${toolbox.solc.default}
        toolbox.foundry.versions.${toolbox.foundry.default}
      ];
    };
  };
  default = "1";
}
