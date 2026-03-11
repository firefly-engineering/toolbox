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
          or (throw "ruff ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "ruff";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/astral-sh/ruff/releases/download/${version}/ruff-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "ruff-${targetTriple}";

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
          install -m755 ruff $out/bin/ruff

          runHook postInstall
        '';

        meta = {
          description = "An extremely fast Python linter and formatter";
          homepage = "https://github.com/astral-sh/ruff";
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
  versions = toolboxLib.buildVersions "ruff" builders versions;
  default = meta.default;
}
