{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  # solc only provides binaries for x86_64-linux and macOS (universal)
  platformKey = {
    "x86_64-linux"   = "solc-static-linux";
    "aarch64-linux"  = "solc-static-linux-arm";
    "x86_64-darwin"  = "solc-macos";
    "aarch64-darwin" = "solc-macos";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "solc: no binary available for ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "solc ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "solc";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/ethereum/solidity/releases/download/v${version}/${platformKey}";
          hash = platformData.sha256;
        };

        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m755 $src $out/bin/solc

          runHook postInstall
        '';

        meta = {
          description = "Solidity compiler";
          homepage = "https://soliditylang.org/";
          license = lib.licenses.gpl3Only;
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
  versions = toolboxLib.buildVersions "solc" builders versions;
  default = meta.default;
}
