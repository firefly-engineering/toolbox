{ pkgs, lib, toolbox, toolboxLib }:

let
  targetTriple = {
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
    "aarch64-linux" = "aarch64-unknown-linux-gnu";
    "x86_64-darwin" = "x86_64-apple-darwin";
    "aarch64-darwin" = "aarch64-apple-darwin";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "difftastic ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "difftastic";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/Wilfred/difftastic/releases/download/${version}/difft-${targetTriple}.tar.gz";
          hash = platformData.sha256;
        };

        sourceRoot = ".";

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
          install -m755 difft $out/bin/difft
          runHook postInstall
        '';

        meta = with lib; {
          description = "A structural diff tool that understands syntax";
          homepage = "https://difftastic.wilfred.me.uk";
          license = licenses.mit;
          mainProgram = "difft";
        };
      };
  };
in
toolboxLib.buildPackage { name = "difftastic"; dataPath = ./data.json; inherit builders; }
