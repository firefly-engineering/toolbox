{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  assetName = {
    "x86_64-linux"   = "biome-linux-x64";
    "aarch64-linux"  = "biome-linux-arm64";
    "x86_64-darwin"  = "biome-darwin-x64";
    "aarch64-darwin" = "biome-darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "biome ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "biome";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/biomejs/biome/releases/download/%40biomejs/biome%40${version}/${assetName}";
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
          install -m755 $src $out/bin/biome

          runHook postInstall
        '';

        meta = {
          description = "Toolchain of the web: formatter, linter, and more";
          homepage = "https://biomejs.dev/";
          license = with lib.licenses; [ asl20 mit ];
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
  versions = toolboxLib.buildVersions "biome" builders versions;
  default = meta.default;
}
