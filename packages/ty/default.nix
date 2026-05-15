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
          or (throw "ty ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "ty";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/astral-sh/ty/releases/download/${version}/ty-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "ty-${targetTriple}";

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

          install -Dm755 ty $out/bin/ty

          runHook postInstall
        '';

        meta = with lib; {
          description = "An extremely fast Python type checker, written in Rust";
          homepage = "https://github.com/astral-sh/ty";
          license = with licenses; [ asl20 mit ];
          mainProgram = "ty";
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
  versions = toolboxLib.buildVersions "ty" builders versions;
  default = meta.default;
}
