{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "beadwork";
    owner = "jallum";
    repo = "beadwork";
    subPackages = [ "cmd/bw" ];
    extraArgs = { versionData, ... }: {
      patches = toolboxLib.resolvePatches ./. versionData;
      nativeBuildInputs = [ pkgs.git ];
    };
    meta = with lib; {
      description = "A git-native work management tool for AI coding agents";
      homepage = "https://github.com/jallum/beadwork";
      license = licenses.mit;
      mainProgram = "bw";
    };
  };
in
toolboxLib.buildPackage { name = "beadwork"; dataPath = ./data.json; inherit builders; }
