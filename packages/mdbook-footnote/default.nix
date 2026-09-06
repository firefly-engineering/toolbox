{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "mdbook-footnote";
    owner = "daviddrysdale";
    repo = "mdbook-footnote";
    extraArgs.cargoBuildFlags = [ "--bin" "mdbook-footnote" ];
    meta = with lib; {
      description = "A preprocessor for mdbook to support footnotes";
      homepage = "https://github.com/daviddrysdale/mdbook-footnote";
      license = licenses.asl20;
      mainProgram = "mdbook-footnote";
    };
  };
in
toolboxLib.buildPackage { name = "mdbook-footnote"; dataPath = ./data.json; inherit builders; }
