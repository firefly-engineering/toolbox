{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  platformKey = {
    "x86_64-linux"   = "linux-amd64";
    "aarch64-linux"  = "linux-arm64";
    "x86_64-darwin"  = "macos-amd64";
    "aarch64-darwin" = "macos-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "jq ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "jq";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/jqlang/jq/releases/download/jq-${version}/jq-${platformKey}";
          hash = platformData.sha256;
        };

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m755 $src $out/bin/jq

          runHook postInstall
        '';

        meta = {
          description = "Lightweight and flexible command-line JSON processor";
          homepage = "https://jqlang.github.io/jq/";
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
{
  versions = toolboxLib.buildVersions "jq" builders versions;
  default = meta.default;
}
