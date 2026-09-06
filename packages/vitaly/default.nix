{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildRustPackage {
    inherit pkgs toolbox;
    pname = "vitaly";
    owner = "bskaplou";
    repo = "vitaly";
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
      description = "Vial-compatible CLI tool for QMK keyboards";
      homepage = "https://github.com/bskaplou/vitaly";
      mainProgram = "vitaly";
    };
  };
in
toolboxLib.buildPackage { name = "vitaly"; dataPath = ./data.json; inherit builders; }
