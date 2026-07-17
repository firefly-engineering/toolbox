{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "mdbook-graphviz";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "dylanowen";
          repo = "mdbook-graphviz";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        cargoBuildFlags = [ "--bin" "mdbook-graphviz" ];
        doCheck = false;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        postInstall = ''
          wrapProgram $out/bin/mdbook-graphviz \
            --prefix PATH : ${lib.makeBinPath [ pkgs.graphviz ]}
        '';

        meta = with lib; {
          description = "A preprocessor for mdbook to render Graphviz diagrams";
          homepage = "https://github.com/dylanowen/mdbook-graphviz";
          license = licenses.mpl20;
          mainProgram = "mdbook-graphviz";
        };
      };
  };
in
toolboxLib.buildPackage { name = "mdbook-graphviz"; dataPath = ./data.json; inherit builders; }
