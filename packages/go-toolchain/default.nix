{ pkgs, lib, toolbox, toolboxLib }:
{
  versions = {
    "1" = pkgs.symlinkJoin {
      name = "go-toolchain-1";
      paths = [
        toolbox.go.versions.${toolbox.go.default}
        toolbox.golangci-lint.versions.${toolbox.golangci-lint.default}
        toolbox.gopls.versions.${toolbox.gopls.default}
      ];
    };
  };
  default = "1";
}
