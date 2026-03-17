{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

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
{
  versions = toolboxLib.buildVersions "mdbook-graphviz" builders versions;
  default = meta.default;
}
