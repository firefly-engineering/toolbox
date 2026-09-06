{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "reindeer";
    owner = "facebookincubator";
    repo = "reindeer";
    # Facebook uses v-prefixed calver tags, which is the default rev shape.
    extraArgs = {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
    };
    meta = with lib; {
      description = "Reindeer: generate Buck build rules from Cargo";
      homepage = "https://github.com/facebookincubator/reindeer";
      license = licenses.mit;
      mainProgram = "reindeer";
    };
  };
in
toolboxLib.buildPackage { name = "reindeer"; dataPath = ./data.json; inherit builders; }
