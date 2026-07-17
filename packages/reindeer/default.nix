{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "reindeer";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "facebookincubator";
          repo = "reindeer";
          rev = "v${version}";  # Facebook uses v-prefixed calver tags
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ];

        doCheck = false;

        meta = with lib; {
          description = "Reindeer: generate Buck build rules from Cargo";
          homepage = "https://github.com/facebookincubator/reindeer";
          license = licenses.mit;
          mainProgram = "reindeer";
        };
      };
  };
in
toolboxLib.buildPackage { name = "reindeer"; dataPath = ./data.json; inherit builders; }
