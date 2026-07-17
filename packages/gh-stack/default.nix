{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "gh-stack";
    platforms = {
      "x86_64-linux" = "linux-amd64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-amd64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/github/gh-stack/releases/download/v${version}/${platform}";
    binaries = [ "gh-stack" ];
    meta = with lib; {
      description = "GitHub CLI extension for stacked pull requests";
      homepage = "https://github.com/github/gh-stack";
      license = licenses.mit;
      mainProgram = "gh-stack";
    };
  };
in
toolboxLib.buildPackage { name = "gh-stack"; dataPath = ./data.json; inherit builders; }
