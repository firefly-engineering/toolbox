{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "jrsonnet";
    owner = "CertainLach";
    repo = "jrsonnet";
    extraArgs.cargoBuildFlags = [ "--bin" "jrsonnet" ];
    meta = with lib; {
      description = "Rust implementation of Jsonnet language";
      homepage = "https://github.com/CertainLach/jrsonnet";
      license = licenses.mit;
      mainProgram = "jrsonnet";
    };
  };
in
toolboxLib.buildPackage { name = "jrsonnet"; dataPath = ./data.json; inherit builders; }
