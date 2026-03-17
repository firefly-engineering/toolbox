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
        pname = "mdbook-mermaid";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "badboy";
          repo = "mdbook-mermaid";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        cargoBuildFlags = [ "--bin" "mdbook-mermaid" ];
        doCheck = false;

        meta = with lib; {
          description = "A preprocessor for mdbook to add mermaid.js support";
          homepage = "https://github.com/badboy/mdbook-mermaid";
          license = licenses.mpl20;
          mainProgram = "mdbook-mermaid";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "mdbook-mermaid" builders versions;
  default = meta.default;
}
