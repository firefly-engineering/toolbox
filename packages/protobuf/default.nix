{ pkgs, lib, toolbox, toolboxLib }:

let
  assetPlatform = {
    "x86_64-linux" = "linux-x86_64";
    "aarch64-linux" = "linux-aarch_64";
    "x86_64-darwin" = "osx-x86_64";
    "aarch64-darwin" = "osx-aarch_64";
  }.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  builders = {
    default = version: versionData:
      let
        system = pkgs.stdenv.hostPlatform.system;
        platformData = versionData.${system}
          or (throw "protobuf ${version} has no binary for ${system}");
      in
      pkgs.stdenv.mkDerivation {
        pname = "protobuf";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-${assetPlatform}.zip";
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
          mkdir -p $out/bin $out/include
          install -m755 bin/protoc $out/bin/protoc
          cp -r include/. $out/include/
          runHook postInstall
        '';

        meta = with lib; {
          description = "Protocol Buffers compiler (protoc) and well-known type definitions";
          homepage = "https://protobuf.dev";
          license = licenses.bsd3;
          mainProgram = "protoc";
          platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        };
      };
  };
in
toolboxLib.buildPackage { name = "protobuf"; dataPath = ./data.json; inherit builders; }
