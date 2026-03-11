{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

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
          or (throw "foundry ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "foundry";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/foundry-rs/foundry/releases/download/${version}/foundry_${version}_${platformKey}.tar.gz";
          hash = platformData.sha256;
        };

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

          mkdir -p $out/bin
          install -m755 forge $out/bin/forge
          install -m755 cast $out/bin/cast
          install -m755 anvil $out/bin/anvil
          install -m755 chisel $out/bin/chisel

          runHook postInstall
        '';

        meta = {
          description = "Blazing fast, portable and modular toolkit for Ethereum development";
          homepage = "https://getfoundry.sh/";
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
  versions = toolboxLib.buildVersions "foundry" builders versions;
  default = meta.default;
}
