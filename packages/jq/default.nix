{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "jq";
    platforms = {
      "x86_64-linux"   = "linux-amd64";
      "aarch64-linux"  = "linux-arm64";
      "x86_64-darwin"  = "macos-amd64";
      "aarch64-darwin" = "macos-arm64";
    };
    url = { version, platform }:
      "https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${platform}";
    binaries = [ "jq" ];
    patchelf = false;
    meta = {
      description = "Lightweight and flexible command-line JSON processor";
      homepage = "https://jqlang.github.io/jq/";
      license = lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "jq"; dataPath = ./data.json; inherit builders; }
