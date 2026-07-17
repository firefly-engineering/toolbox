{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "yq";
    platforms = {
      "x86_64-linux" = "linux_amd64";
      "aarch64-linux" = "linux_arm64";
      "x86_64-darwin" = "darwin_amd64";
      "aarch64-darwin" = "darwin_arm64";
    };
    url = { version, platform }:
      "https://github.com/mikefarah/yq/releases/download/v${version}/yq_${platform}";
    binaries = [ "yq" ];
    patchelf = false;
    meta = with lib; {
      description = "Portable command-line YAML, JSON, XML, CSV, TOML and properties processor";
      homepage = "https://mikefarah.gitbook.io/yq/";
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
toolboxLib.buildPackage { name = "yq"; dataPath = ./data.json; inherit builders; }
