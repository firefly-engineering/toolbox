{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "uv";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/astral-sh/uv/releases/download/${version}/uv-${platform}.tar.gz";
    binaries = [ "uv" "uvx" ];
    sourceRoot = { version, platform }: "uv-${platform}";
    meta = with lib; {
      description = "An extremely fast Python package installer and resolver";
      homepage = "https://github.com/astral-sh/uv";
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
toolboxLib.buildPackage { name = "uv"; dataPath = ./data.json; inherit builders; }
