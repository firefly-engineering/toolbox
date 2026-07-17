{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "qmk_hid";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "FrameworkComputer";
          repo = "qmk_hid";
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
          description = "Commandline tool to interact with QMK devices via their raw HID interface";
          homepage = "https://github.com/FrameworkComputer/qmk_hid";
          license = licenses.bsd3;
          mainProgram = "qmk_hid";
        };
      };
  };
in
toolboxLib.buildPackage { name = "qmk_hid"; dataPath = ./data.json; inherit builders; }
