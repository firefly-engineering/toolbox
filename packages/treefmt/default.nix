{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "treefmt";
    platforms = {
      "x86_64-linux" = "linux_amd64";
      "aarch64-linux" = "linux_arm64";
      "x86_64-darwin" = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/numtide/treefmt/releases/download/v${version}/treefmt_${version}_${platform}.tar.gz";
    binaries = [ "treefmt" ];
    sourceRoot = ".";
    patchelf = false;
    meta = with lib; {
      description = "one CLI to format the code tree";
      homepage = "https://github.com/numtide/treefmt";
      license = licenses.mit;
      mainProgram = "treefmt";
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
toolboxLib.buildPackage { name = "treefmt"; dataPath = ./data.json; inherit builders; }
