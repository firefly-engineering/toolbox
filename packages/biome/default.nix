{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "biome";
    platforms = {
      "x86_64-linux" = "biome-linux-x64";
      "aarch64-linux" = "biome-linux-arm64";
      "x86_64-darwin" = "biome-darwin-x64";
      "aarch64-darwin" = "biome-darwin-arm64";
    };
    url = { version, platform }:
      "https://github.com/biomejs/biome/releases/download/%40biomejs/biome%40${version}/${platform}";
    binaries = [ "biome" ];
    meta = with lib; {
      description = "Toolchain of the web: formatter, linter, and more";
      homepage = "https://biomejs.dev/";
      license = with lib.licenses; [ asl20 mit ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "biome"; dataPath = ./data.json; inherit builders; }
