{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "tuicr";
    platforms = {
      "x86_64-linux"   = "x86_64-unknown-linux-gnu";
      "aarch64-linux"  = "aarch64-unknown-linux-gnu";
      "x86_64-darwin"  = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/agavra/tuicr/releases/download/v${version}/tuicr-${version}-${platform}.tar.gz";
    sourceRoot = ".";
    binaries = [ "tuicr" ];
    meta = with lib; {
      description = "A code review TUI with vim keybindings";
      homepage = "https://github.com/agavra/tuicr";
      license = licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      mainProgram = "tuicr";
    };
  };
in
toolboxLib.buildPackage { name = "tuicr"; dataPath = ./data.json; inherit builders; }
