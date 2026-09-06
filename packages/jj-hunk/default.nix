{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "jj-hunk";
    owner = "laulauland";
    repo = "jj-hunk";
    extraArgs = { versionData, ... }: {
      cargoPatches = toolboxLib.resolvePatches ./. versionData;
    };
    meta = with lib; {
      description = "Programmatic hunk selection for jj";
      homepage = "https://github.com/laulauland/jj-hunk";
      license = licenses.mit;
      mainProgram = "jj-hunk";
    };
  };
in
toolboxLib.buildPackage { name = "jj-hunk"; dataPath = ./data.json; inherit builders; }
