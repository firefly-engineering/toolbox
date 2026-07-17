{ pkgs, lib, toolbox, toolboxLib }:

let
  assetName = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "gh-stack ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "gh-stack";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/github/gh-stack/releases/download/v${version}/${assetName}";
          hash = platformData.sha256;
        };

        dontUnpack = true;
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
          mkdir -p $out/bin
          install -m755 $src $out/bin/gh-stack
          runHook postInstall
        '';

        meta = with lib; {
          description = "GitHub CLI extension for stacked pull requests";
          homepage = "https://github.com/github/gh-stack";
          license = licenses.mit;
          mainProgram = "gh-stack";
        };
      };
  };
in
toolboxLib.buildPackage { name = "gh-stack"; dataPath = ./data.json; inherit builders; }
