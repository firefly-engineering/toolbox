{ pkgs, lib, toolbox, toolboxLib }:

# Prebuilt where upstream releases a binary; built from the same tag elsewhere
# (aarch64-linux has no release asset).
let
  system = pkgs.stdenv.hostPlatform.system;

  meta = {
    description = "Plan, apply and roll back changes to a production ontology, with a blast radius report and an auditable proof";
    homepage = "https://github.com/fabio-rovai/open-ontologies";
    license = lib.licenses.mit;
  };

  mkPrebuilt = toolboxLib.buildPrebuiltBinary {
    inherit pkgs meta;
    pname = "open-ontologies";
    platforms = {
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };
    url = { version, platform }:
      "https://github.com/fabio-rovai/open-ontologies/releases/download/v${version}/open-ontologies-${platform}";
    binaries = [ "open-ontologies" ];
    extraLibs = [ pkgs.openssl ];
  };

  mkFromSource = toolboxLib.buildRustPackage {
    inherit pkgs toolbox meta;
    pname = "open-ontologies";
    owner = "fabio-rovai";
    repo = "open-ontologies";
    extraArgs = {
      # oxrocksdb-sys generates its RocksDB bindings with bindgen.
      nativeBuildInputs = [ pkgs.pkg-config pkgs.rustPlatform.bindgenHook ];
      buildInputs = [ pkgs.openssl ];
    };
  };

  builders.default = version: versionData:
    if versionData ? ${system} then
      mkPrebuilt version versionData
    else
      mkFromSource version versionData;
in
toolboxLib.buildPackage { name = "open-ontologies"; dataPath = ./data.json; inherit builders; }
