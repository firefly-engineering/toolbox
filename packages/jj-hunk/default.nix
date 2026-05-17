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
        pname = "jj-hunk";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "laulauland";
          repo = "jj-hunk";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoPatches = toolboxLib.resolvePatches ./. versionData;
        cargoHash = versionData.cargoHash;
        doCheck = false;

        meta = with lib; {
          description = "Programmatic hunk selection for jj";
          homepage = "https://github.com/laulauland/jj-hunk";
          license = licenses.mit;
          mainProgram = "jj-hunk";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "jj-hunk" builders versions;
  default = meta.default;
}
