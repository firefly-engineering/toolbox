{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  mkBuilder = extraArgs: version: versionData:
    let
      go = toolbox.go.versions.${versionData.go};
    in
    (pkgs.buildGoModule.override { inherit go; }) ({
      pname = "go-licenses";
      inherit version;
      src = pkgs.fetchFromGitHub {
        owner = "google";
        repo = "go-licenses";
        rev = "v${version}";
        hash = versionData.sha256;
      };
      vendorHash = versionData.vendorHash;
      subPackages = [ "." ];
      doCheck = false;

      meta = with lib; {
        description = "Reports on the licenses used by a Go package and its dependencies";
        homepage = "https://github.com/google/go-licenses";
        license = licenses.asl20;
        mainProgram = "go-licenses";
      };
    } // extraArgs);

  builders = {
    default = mkBuilder { };
    legacy = mkBuilder {
      proxyVendor = true;
    };
  };
in
{
  versions = toolboxLib.buildVersions "go-licenses" builders versions;
  default = meta.default;
}
