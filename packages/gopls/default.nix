{ pkgs, lib, toolbox, toolboxLib }:

let
  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "gopls";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "golang";
          repo = "tools";
          rev = "gopls/v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;

        sourceRoot = "source/gopls";
        subPackages = [ "." ];
        doCheck = false;

        meta = with lib; {
          description = "Official Go language server";
          homepage = "https://pkg.go.dev/golang.org/x/tools/gopls";
          license = licenses.bsd3;
          mainProgram = "gopls";
        };
      };
  };
in
toolboxLib.buildPackage { name = "gopls"; dataPath = ./data.json; inherit builders; }
