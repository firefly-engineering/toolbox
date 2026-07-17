{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "solc";
    platforms = {
      "x86_64-linux" = "solc-static-linux";
      "aarch64-linux" = "solc-static-linux-arm";
      "x86_64-darwin" = "solc-macos";
      "aarch64-darwin" = "solc-macos";
    };
    url = { version, platform }:
      "https://github.com/ethereum/solidity/releases/download/v${version}/${platform}";
    binaries = [ "solc" ];
    patchelf = false;
    meta = with lib; {
      description = "Solidity compiler";
      homepage = "https://soliditylang.org/";
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
toolboxLib.buildPackage { name = "solc"; dataPath = ./data.json; inherit builders; }
