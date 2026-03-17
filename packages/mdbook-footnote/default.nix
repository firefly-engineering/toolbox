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
        pname = "mdbook-footnote";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "daviddrysdale";
          repo = "mdbook-footnote";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        cargoBuildFlags = [ "--bin" "mdbook-footnote" ];
        doCheck = false;

        meta = with lib; {
          description = "A preprocessor for mdbook to support footnotes";
          homepage = "https://github.com/daviddrysdale/mdbook-footnote";
          license = licenses.asl20;
          mainProgram = "mdbook-footnote";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "mdbook-footnote" builders versions;
  default = meta.default;
}
