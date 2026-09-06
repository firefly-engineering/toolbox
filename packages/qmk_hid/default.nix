{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "qmk_hid";
    owner = "FrameworkComputer";
    repo = "qmk_hid";
    extraArgs = {
      cargoLock.lockFile = ./Cargo.lock;

      nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.pkg-config
      ];

      buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.udev
      ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.apple-sdk_15
      ];
    };
    meta = with lib; {
      description = "Commandline tool to interact with QMK devices via their raw HID interface";
      homepage = "https://github.com/FrameworkComputer/qmk_hid";
      license = licenses.bsd3;
      mainProgram = "qmk_hid";
    };
  };
in
toolboxLib.buildPackage { name = "qmk_hid"; dataPath = ./data.json; inherit builders; }
