{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "gh-aw";
    platforms = {
      "x86_64-linux" = "linux-amd64";
      "aarch64-linux" = "linux-arm64";
      "x86_64-darwin" = "darwin-amd64";
      "aarch64-darwin" = "darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/github/gh-aw/releases/download/v${version}/${platform}";
    binaries = [ "gh-aw" ];
    meta = with lib; {
      description = "GitHub CLI extension for activity watching";
      homepage = "https://github.com/github/gh-aw";
      license = licenses.mit;
      mainProgram = "gh-aw";
    };
  };
in
toolboxLib.buildPackage { name = "gh-aw"; dataPath = ./data.json; inherit builders; }
