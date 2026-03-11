{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "rust-toolchain-1";
      paths = [
        toolbox.rust.versions.${toolbox.rust.default}
        toolbox.rust-analyzer.versions.${toolbox.rust-analyzer.default}
        toolbox.cargo-edit.versions.${toolbox.cargo-edit.default}
      ];
    };
  };
  default = "1";
}
