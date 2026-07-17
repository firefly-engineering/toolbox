{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "protoc-gen-go";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "protocolbuffers";
          repo = "protobuf-go";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;
        subPackages = [ "cmd/protoc-gen-go" ];
        doCheck = false;

        meta = with lib; {
          description = "Protocol buffers compiler plugin for Go";
          homepage = "https://github.com/protocolbuffers/protobuf-go";
          license = licenses.bsd3;
          mainProgram = "protoc-gen-go";
        };
      };
  };
in
toolboxLib.buildPackage { name = "protoc-gen-go"; dataPath = ./data.json; inherit builders; }
