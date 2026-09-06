{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "mdbook-admonish";
    owner = "tommilligan";
    repo = "mdbook-admonish";
    extraArgs.cargoBuildFlags = [ "--bin" "mdbook-admonish" ];
    meta = with lib; {
      description = "A preprocessor for mdbook to add Material Design admonishments";
      homepage = "https://github.com/tommilligan/mdbook-admonish";
      license = licenses.mit;
      mainProgram = "mdbook-admonish";
    };
  };
in
toolboxLib.buildPackage { name = "mdbook-admonish"; dataPath = ./data.json; inherit builders; }
