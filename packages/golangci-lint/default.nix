{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "golangci-lint";
    platforms = {
      "x86_64-linux" = "linux-amd64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-amd64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${platform}.tar.gz";
    binaries = [ "golangci-lint" ];
    sourceRoot = { version, platform }: "golangci-lint-${version}-${platform}";
    meta = with lib; {
      description = "Fast Go linters runner";
      homepage = "https://golangci-lint.run/";
      license = lib.licenses.gpl3Only;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "golangci-lint"; dataPath = ./data.json; inherit builders; }
