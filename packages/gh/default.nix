{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "gh";
    platforms = {
      "x86_64-linux" = "linux_amd64.tar.gz";
      "aarch64-linux" = "linux_arm64.tar.gz";
      "x86_64-darwin" = "macOS_amd64.zip";
      "aarch64-darwin" = "macOS_arm64.zip";
    };
    url = { version, platform }:
      "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${platform}";
    binaries = [ "bin/gh" ];
    sourceRoot = { version, platform }: "gh_${version}_${builtins.replaceStrings [ ".tar.gz" ".zip" ] [ "" "" ] platform}";
    meta = with lib; {
      description = "GitHub's official command line tool";
      homepage = "https://cli.github.com";
      license = licenses.mit;
      mainProgram = "gh";
    };
  };
in
toolboxLib.buildPackage { name = "gh"; dataPath = ./data.json; inherit builders; }
