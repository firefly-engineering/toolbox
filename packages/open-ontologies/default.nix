{ pkgs, lib, toolbox, toolboxLib }:

let
  # Upstream ships no aarch64-linux binary.
  builders.default = toolboxLib.buildPrebuiltBinary {
    inherit pkgs;
    pname = "open-ontologies";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/fabio-rovai/open-ontologies/releases/download/v${version}/open-ontologies-${platform}";
    binaries = [ "open-ontologies" ];
    extraLibs = [ pkgs.openssl ];
    meta = {
      description = "Plan, apply and roll back changes to a production ontology, with a blast radius report and an auditable proof";
      homepage = "https://github.com/fabio-rovai/open-ontologies";
      license = lib.licenses.mit;
    };
  };
in
toolboxLib.buildPackage { name = "open-ontologies"; dataPath = ./data.json; inherit builders; }
