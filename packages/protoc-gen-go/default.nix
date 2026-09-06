{ pkgs, lib, toolbox, toolboxLib }:

let
  builders.default = toolboxLib.buildGoPackage {
    inherit pkgs toolbox;
    pname = "protoc-gen-go";
    owner = "protocolbuffers";
    repo = "protobuf-go";
    subPackages = [ "cmd/protoc-gen-go" ];
    meta = with lib; {
      description = "Protocol buffers compiler plugin for Go";
      homepage = "https://github.com/protocolbuffers/protobuf-go";
      license = licenses.bsd3;
      mainProgram = "protoc-gen-go";
    };
  };
in
toolboxLib.buildPackage { name = "protoc-gen-go"; dataPath = ./data.json; inherit builders; }
