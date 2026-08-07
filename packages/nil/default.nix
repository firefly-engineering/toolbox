{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "nil";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "oxalica";
          repo = "nil";
          rev = version;
          hash = versionData.sha256;
        };
        # nil's Cargo.lock is vendored version-namespaced: the upstream lock is
        # only reachable through `src`, and reading it from the store at eval
        # time would be import-from-derivation.
        cargoLock = {
          lockFile = ./. + "/Cargo-${version}.lock";
        };
        doCheck = false;

        nativeBuildInputs = [ pkgs.nix ];

        env.CFG_RELEASE = version;

        # nil's `builtin` crate shells out to `nix` at build time; give it a
        # writable state dir inside the sandbox.
        # https://github.com/NixOS/nix/issues/5884
        preBuild = ''
          export NIX_STATE_DIR=$(mktemp -d)
        '';

        meta = with lib; {
          description = "Yet another language server for Nix";
          homepage = "https://github.com/oxalica/nil";
          license = with licenses; [ mit asl20 ];
          mainProgram = "nil";
        };
      };
  };
in
toolboxLib.buildPackage { name = "nil"; dataPath = ./data.json; inherit builders; }
