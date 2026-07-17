{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "ruff";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/astral-sh/ruff/releases/download/${version}/ruff-${platform}.tar.gz";
    binaries = [ "ruff" ];
    sourceRoot = { version, platform }: "ruff-${platform}";
    meta = with lib; {
      description = "An extremely fast Python linter and formatter";
      homepage = "https://github.com/astral-sh/ruff";
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
toolboxLib.buildPackage { name = "ruff"; dataPath = ./data.json; inherit builders; }
