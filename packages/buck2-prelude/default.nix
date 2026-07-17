{ pkgs, lib, toolbox, toolboxLib }:

let
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
toolboxLib.buildPackage { name = "buck2-prelude"; dataPath = ./data.json; inherit builders; }
