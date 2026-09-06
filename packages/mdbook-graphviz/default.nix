{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "mdbook-graphviz";
    owner = "dylanowen";
    repo = "mdbook-graphviz";
    extraArgs = {
      cargoBuildFlags = [ "--bin" "mdbook-graphviz" ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postInstall = ''
        wrapProgram $out/bin/mdbook-graphviz \
          --prefix PATH : ${lib.makeBinPath [ pkgs.graphviz ]}
      '';
    };
    meta = with lib; {
      description = "A preprocessor for mdbook to render Graphviz diagrams";
      homepage = "https://github.com/dylanowen/mdbook-graphviz";
      license = licenses.mpl20;
      mainProgram = "mdbook-graphviz";
    };
  };
in
toolboxLib.buildPackage { name = "mdbook-graphviz"; dataPath = ./data.json; inherit builders; }
