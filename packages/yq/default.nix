{ pkgs, lib, toolbox, toolboxLib }:

let
  platformKey = {
    "x86_64-linux"   = "linux_amd64";
    "aarch64-linux"  = "linux_arm64";
    "x86_64-darwin"  = "darwin_amd64";
    "aarch64-darwin" = "darwin_arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "yq ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "yq";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/mikefarah/yq/releases/download/v${version}/yq_${platformKey}";
          hash = platformData.sha256;
        };

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m755 $src $out/bin/yq

          runHook postInstall
        '';

        meta = {
          description = "Portable command-line YAML, JSON, XML, CSV, TOML and properties processor";
          homepage = "https://mikefarah.gitbook.io/yq/";
          license = lib.licenses.mit;
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "yq"; dataPath = ./data.json; inherit builders; }
