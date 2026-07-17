{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "mdbook-admonish";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "tommilligan";
          repo = "mdbook-admonish";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        cargoBuildFlags = [ "--bin" "mdbook-admonish" ];
        doCheck = false;

        meta = with lib; {
          description = "A preprocessor for mdbook to add Material Design admonishments";
          homepage = "https://github.com/tommilligan/mdbook-admonish";
          license = licenses.mit;
          mainProgram = "mdbook-admonish";
        };
      };
  };
in
toolboxLib.buildPackage { name = "mdbook-admonish"; dataPath = ./data.json; inherit builders; }
