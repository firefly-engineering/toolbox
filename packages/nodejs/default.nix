{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  platformKey = {
    "x86_64-linux"   = "linux-x64";
    "aarch64-linux"  = "linux-arm64";
    "x86_64-darwin"  = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "nodejs ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "nodejs";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://nodejs.org/dist/v${version}/node-v${version}-${platformKey}.tar.xz";
          hash = platformData.sha256;
        };

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

          mkdir -p $out
          cp -r bin lib include share $out/

          runHook postInstall
        '';

        meta = {
          description = "Event-driven I/O framework for the V8 JavaScript engine";
          homepage = "https://nodejs.org/";
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
  versions = toolboxLib.buildVersions "nodejs" builders versions;
  default = meta.default;
}
