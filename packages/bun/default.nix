{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  platformKey = {
    "x86_64-linux"   = "linux-x64";
    "aarch64-linux"  = "linux-aarch64";
    "x86_64-darwin"  = "darwin-x64";
    "aarch64-darwin" = "darwin-aarch64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "bun ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "bun";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platformKey}.zip";
          hash = platformData.sha256;
        };

        sourceRoot = "bun-${platformKey}";

        nativeBuildInputs = [
          pkgs.unzip
        ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          install -m 755 bun $out/bin/bun
          ln -s $out/bin/bun $out/bin/bunx

          runHook postInstall
        '';

        meta = {
          description = "Incredibly fast JavaScript runtime, bundler, test runner, and package manager";
          homepage = "https://bun.sh";
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
  versions = toolboxLib.buildVersions "bun" builders versions;
  default = meta.default;
}
