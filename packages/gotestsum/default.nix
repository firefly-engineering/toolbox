{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "gotestsum";
    owner = "gotestyourself";
    repo = "gotestsum";
    meta = with lib; {
      description = "Human-friendly test runner for go test";
      homepage = "https://github.com/gotestyourself/gotestsum";
      license = licenses.asl20;
      mainProgram = "gotestsum";
    };
  };
in
toolboxLib.buildPackage { name = "gotestsum"; dataPath = ./data.json; inherit builders; }
