{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "python-toolchain-1";
      paths = [
        toolbox.python.versions.${toolbox.python.default}
        toolbox.uv.versions.${toolbox.uv.default}
        toolbox.ruff.versions.${toolbox.ruff.default}
      ];
    };
  };
  default = "1";
}
