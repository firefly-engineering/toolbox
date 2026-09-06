{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "beads-rust";
    owner = "Dicklesworthstone";
    repo = "beads_rust";
    extraArgs = {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
    };
    meta = with lib; {
      description = "Local-first, non-invasive issue tracker storing tasks in SQLite";
      homepage = "https://github.com/Dicklesworthstone/beads_rust";
      license = licenses.mit;
      mainProgram = "br";
    };
  };
in
toolboxLib.buildPackage { name = "beads-rust"; dataPath = ./data.json; inherit builders; }
