{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "mdbook-mermaid";
    owner = "badboy";
    repo = "mdbook-mermaid";
    extraArgs.cargoBuildFlags = [ "--bin" "mdbook-mermaid" ];
    meta = with lib; {
      description = "A preprocessor for mdbook to add mermaid.js support";
      homepage = "https://github.com/badboy/mdbook-mermaid";
      license = licenses.mpl20;
      mainProgram = "mdbook-mermaid";
    };
  };
in
toolboxLib.buildPackage { name = "mdbook-mermaid"; dataPath = ./data.json; inherit builders; }
