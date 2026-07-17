{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "ty";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/astral-sh/ty/releases/download/${version}/ty-${platform}.tar.gz";
    binaries = [ "ty" ];
    sourceRoot = { version, platform }: "ty-${platform}";
    meta = with lib; {
      description = "An extremely fast Python type checker, written in Rust";
      homepage = "https://github.com/astral-sh/ty";
      license = with licenses; [ asl20 mit ];
      mainProgram = "ty";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
in
toolboxLib.buildPackage { name = "ty"; dataPath = ./data.json; inherit builders; }
