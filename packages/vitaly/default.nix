{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "vitaly";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "bskaplou";
          repo = "vitaly";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoLock.lockFile = ./Cargo.lock;

        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.pkg-config
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.udev
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          pkgs.apple-sdk_15
        ];

        doCheck = false;

        meta = with lib; {
          description = "Vial-compatible CLI tool for QMK keyboards";
          homepage = "https://github.com/bskaplou/vitaly";
          mainProgram = "vitaly";
        };
      };
  };
in
toolboxLib.buildPackage { name = "vitaly"; dataPath = ./data.json; inherit builders; }
