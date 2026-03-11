{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  targetTriple = {
    "x86_64-linux"   = "x86_64-unknown-linux-gnu";
    "aarch64-linux"  = "aarch64-unknown-linux-gnu";
    "x86_64-darwin"  = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "uv ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "uv";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/astral-sh/uv/releases/download/${version}/uv-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "uv-${targetTriple}";

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
          install -m755 uv $out/bin/uv
          install -m755 uvx $out/bin/uvx

          runHook postInstall
        '';

        meta = {
          description = "An extremely fast Python package installer and resolver";
          homepage = "https://github.com/astral-sh/uv";
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
  versions = toolboxLib.buildVersions "uv" builders versions;
  default = meta.default;
}
