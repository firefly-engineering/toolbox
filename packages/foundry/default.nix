{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "foundry";
    platforms = {
      "x86_64-linux" = "linux_amd64";
      "aarch64-linux" = "linux_arm64";
      "x86_64-darwin" = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/foundry-rs/foundry/releases/download/${version}/foundry_${version}_${platform}.tar.gz";
    binaries = [ "forge" "cast" "anvil" "chisel" ];
    sourceRoot = ".";
    meta = with lib; {
      description = "Blazing fast, portable and modular toolkit for Ethereum development";
      homepage = "https://getfoundry.sh/";
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
toolboxLib.buildPackage { name = "foundry"; dataPath = ./data.json; inherit builders; }
