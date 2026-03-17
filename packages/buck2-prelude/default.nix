{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      pkgs.fetchFromGitHub {
        owner = "facebook";
        repo = "buck2-prelude";
        rev = versionData.rev;
        hash = versionData.sha256;

        # Attach version metadata for downstream consumers
        passthru = {
          inherit version;
          preludeRev = versionData.rev;
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "buck2-prelude" builders versions;
  default = meta.default;
}
