{ pkgs, lib, toolbox, toolboxLib }:

let
  platformKey = {
    "x86_64-linux"   = "linux-x64";
    "aarch64-linux"  = "linux-arm64";
    "aarch64-darwin" = "darwin-arm64";
  };

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platform = platformKey.${system}
          or (throw "pnpm ${version} has no binary for ${system}");
        platformData = versionData.${system}
          or (throw "pnpm ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "pnpm";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-${platform}.tar.gz";
          hash = platformData.sha256;
        };

        # Tarball unpacks to a flat layout (the `pnpm` launcher + its `dist/`).
        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall

          # The `pnpm` launcher loads `dist/pnpm.mjs` relative to its own real
          # path, so the binary and its `dist/` tree must stay together.
          mkdir -p $out/libexec/pnpm
          cp -r pnpm dist $out/libexec/pnpm/

          mkdir -p $out/bin
          ln -s $out/libexec/pnpm/pnpm $out/bin/pnpm

          runHook postInstall
        '';

        # nixpkgs' `fetchPnpmDeps` reads `pnpm.nodejs-slim` (to build its
        # `pnpm-fixup-state-db` helper), so expose it the way nixpkgs' own pnpm
        # derivation does — that makes this package a drop-in for the nixpkgs
        # pnpm build helpers.
        passthru = {
          inherit (pkgs) nodejs-slim;
        };

        meta = {
          description = "Fast, disk space efficient package manager for JavaScript";
          homepage = "https://pnpm.io/";
          license = lib.licenses.mit;
          mainProgram = "pnpm";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "pnpm"; dataPath = ./data.json; inherit builders; }
