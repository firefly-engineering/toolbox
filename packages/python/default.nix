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
          or (throw "python ${version} has no binary for ${system}");
        release = versionData.release;
      in
      pkgs.stdenv.mkDerivation {
        pname = "python";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/astral-sh/python-build-standalone/releases/download/${release}/cpython-${version}+${release}-${targetTriple}-install_only_stripped.tar.gz";
          hash = platformData.sha256;
        };

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;
        dontFixup = true;

        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r ./* $out/

          runHook postInstall
        '';

        meta = {
          description = "Pre-built CPython from python-build-standalone";
          homepage = "https://github.com/astral-sh/python-build-standalone";
          license = lib.licenses.psfl;
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
  versions = toolboxLib.buildVersions "python" builders versions;
  default = meta.default;
}
