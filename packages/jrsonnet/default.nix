{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      let
        rust = toolbox.rust.versions.${versionData.rust};
        rustPlatform = pkgs.makeRustPlatform { rustc = rust; cargo = rust; };
      in
      rustPlatform.buildRustPackage {
        pname = "jrsonnet";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "CertainLach";
          repo = "jrsonnet";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        cargoBuildFlags = [ "--bin" "jrsonnet" ];
        doCheck = false;

        meta = with lib; {
          description = "Rust implementation of Jsonnet language";
          homepage = "https://github.com/CertainLach/jrsonnet";
          license = licenses.mit;
          mainProgram = "jrsonnet";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "jrsonnet" builders versions;
  default = meta.default;
}
