{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  assetPlatform = {
    "x86_64-linux" = "linux_amd64";
    "aarch64-linux" = "linux_arm64";
    "x86_64-darwin" = "darwin_amd64";
    "aarch64-darwin" = "darwin_arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "treefmt ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "treefmt";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/numtide/treefmt/releases/download/v${version}/treefmt_${version}_${assetPlatform}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          install -m755 treefmt $out/bin/treefmt
          runHook postInstall
        '';

        meta = with lib; {
          description = "one CLI to format the code tree";
          homepage = "https://github.com/numtide/treefmt";
          license = licenses.mit;
          mainProgram = "treefmt";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "treefmt" builders versions;
  default = meta.default;
}
