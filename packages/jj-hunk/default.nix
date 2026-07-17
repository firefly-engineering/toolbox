{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "jj-hunk";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "laulauland";
          repo = "jj-hunk";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoPatches = toolboxLib.resolvePatches ./. versionData;
        cargoHash = versionData.cargoHash;
        doCheck = false;

        meta = with lib; {
          description = "Programmatic hunk selection for jj";
          homepage = "https://github.com/laulauland/jj-hunk";
          license = licenses.mit;
          mainProgram = "jj-hunk";
        };
      };
  };
in
toolboxLib.buildPackage { name = "jj-hunk"; dataPath = ./data.json; inherit builders; }
