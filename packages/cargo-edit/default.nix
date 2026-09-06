{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "cargo-edit";
    owner = "killercup";
    repo = "cargo-edit";
    extraArgs = {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
    };
    meta = with lib; {
      description = "Cargo subcommands for managing dependencies (cargo add, rm, upgrade)";
      homepage = "https://github.com/killercup/cargo-edit";
      license = with licenses; [ asl20 mit ];
      mainProgram = "cargo-add";
    };
  };
in
toolboxLib.buildPackage { name = "cargo-edit"; dataPath = ./data.json; inherit builders; }
