{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  targetTriple = {
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
    "aarch64-linux" = "aarch64-unknown-linux-gnu";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "delta ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "delta";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "delta-${version}-${targetTriple}";

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
          install -m755 delta $out/bin/delta
          runHook postInstall
        '';

        meta = with lib; {
          description = "A syntax-highlighting pager for git, diff, and grep output";
          homepage = "https://github.com/dandavison/delta";
          license = licenses.mit;
          mainProgram = "delta";
          platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "delta" builders versions;
  default = meta.default;
}
