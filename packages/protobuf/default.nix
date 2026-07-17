{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "protobuf";
    platforms = {
      "x86_64-linux" = "linux-x86_64";
      "aarch64-linux" = "linux-aarch_64";
      "x86_64-darwin" = "osx-x86_64";
      "aarch64-darwin" = "osx-aarch_64";
    };
    url = { version, platform }:
      "https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-${platform}.zip";
    binaries = [ "bin/protoc" ];
    sourceRoot = ".";
    postInstall = ''
      mkdir -p $out/include
      cp -r include/. $out/include/
    '';
    meta = with lib; {
      description = "Protocol Buffers compiler (protoc) and well-known type definitions";
      homepage = "https://protobuf.dev";
      license = licenses.bsd3;
      mainProgram = "protoc";
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
toolboxLib.buildPackage { name = "protobuf"; dataPath = ./data.json; inherit builders; }
