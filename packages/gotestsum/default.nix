{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "gotestsum";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "gotestyourself";
          repo = "gotestsum";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;
        subPackages = [ "." ];
        doCheck = false;

        meta = with lib; {
          description = "Human-friendly test runner for go test";
          homepage = "https://github.com/gotestyourself/gotestsum";
          license = licenses.asl20;
          mainProgram = "gotestsum";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "gotestsum" builders versions;
  default = meta.default;
}
