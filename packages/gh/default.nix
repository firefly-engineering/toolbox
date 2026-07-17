{ pkgs, lib, toolbox, toolboxLib }:

let
  assetSuffix = {
    "x86_64-linux" = "linux_amd64.tar.gz";
    "aarch64-linux" = "linux_arm64.tar.gz";
    "x86_64-darwin" = "macOS_amd64.zip";
    "aarch64-darwin" = "macOS_arm64.zip";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "gh ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "gh";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${assetSuffix}";
          hash = platformData.sha256;
        };

        sourceRoot = "gh_${version}_${builtins.replaceStrings [".tar.gz" ".zip"] ["" ""] assetSuffix}";

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
          install -m755 bin/gh $out/bin/gh
          runHook postInstall
        '';

        meta = with lib; {
          description = "GitHub's official command line tool";
          homepage = "https://cli.github.com";
          license = licenses.mit;
          mainProgram = "gh";
        };
      };
  };
in
toolboxLib.buildPackage { name = "gh"; dataPath = ./data.json; inherit builders; }
