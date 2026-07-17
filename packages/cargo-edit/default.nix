{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "cargo-edit";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "killercup";
          repo = "cargo-edit";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ];

        doCheck = false;

        meta = with lib; {
          description = "Cargo subcommands for managing dependencies (cargo add, rm, upgrade)";
          homepage = "https://github.com/killercup/cargo-edit";
          license = with licenses; [ asl20 mit ];
          mainProgram = "cargo-add";
        };
      };
  };
in
toolboxLib.buildPackage { name = "cargo-edit"; dataPath = ./data.json; inherit builders; }
