{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "beadwork";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "jallum";
          repo = "beadwork";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        patches = toolboxLib.resolvePatches ./. versionData;
        vendorHash = versionData.vendorHash;
        subPackages = versionData.subPackages or [ "cmd/bw" ];
        doCheck = false;

        nativeBuildInputs = [ pkgs.git ];

        meta = with lib; {
          description = "A git-native work management tool for AI coding agents";
          homepage = "https://github.com/jallum/beadwork";
          license = licenses.mit;
          mainProgram = "bw";
        };
      };
  };
in
toolboxLib.buildPackage { name = "beadwork"; dataPath = ./data.json; inherit builders; }
