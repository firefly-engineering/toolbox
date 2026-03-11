{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  platformKey = {
    "x86_64-linux"   = "linux-amd64";
    "aarch64-linux"  = "linux-arm64";
    "x86_64-darwin"  = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "golangci-lint ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "golangci-lint";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${platformKey}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = "golangci-lint-${version}-${platformKey}";

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
          install -m755 golangci-lint $out/bin/golangci-lint

          runHook postInstall
        '';

        meta = {
          description = "Fast Go linters runner";
          homepage = "https://golangci-lint.run/";
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
  versions = toolboxLib.buildVersions "golangci-lint" builders versions;
  default = meta.default;
}
