{ pkgs, lib, toolbox }:

let
  data = builtins.fromJSON (builtins.readFile ./data.json);
  meta = data._meta;
  versionEntries = lib.filterAttrs (n: _: n != "_meta") data;

  builders = {
    default = version: versionData:
      pkgs.go_1_25.overrideAttrs (old: {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://go.dev/dl/go${version}.src.tar.gz";
          hash = versionData.sha256;
        };
      });
  };

  buildVersion = version: versionData:
    let
      builderName = versionData.builder or "default";
      builder = builders.${builderName}
        or (throw "Unknown builder '${builderName}' for go ${version}");
    in
    builder version versionData;
in
{
  versions = builtins.mapAttrs buildVersion versionEntries;
  default = meta.default;
}
