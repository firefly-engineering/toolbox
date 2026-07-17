{ pkgs, lib, toolbox, toolboxLib }:

let
  platformSuffix = {
    "x86_64-linux" = "linux-amd64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-amd64";
    "aarch64-darwin" = "darwin-arm64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "jjui ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "jjui";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/idursun/jjui/releases/download/v${version}/jjui-${version}-${platformSuffix}.zip";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

        dontConfigure = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [ pkgs.unzip ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.autoPatchelfHook
        ];

        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          install -m755 jjui-${version}-${platformSuffix} $out/bin/jjui
          runHook postInstall
        '';

        meta = with lib; {
          description = "A TUI for Jujutsu version control";
          homepage = "https://github.com/idursun/jjui";
          license = licenses.mit;
          mainProgram = "jjui";
        };
      };
  };
in
toolboxLib.buildPackage { name = "jjui"; dataPath = ./data.json; inherit builders; }
