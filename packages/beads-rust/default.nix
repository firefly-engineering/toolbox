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
        pname = "beads-rust";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "Dicklesworthstone";
          repo = "beads_rust";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        cargoHash = versionData.cargoHash;

        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        doCheck = false;

        meta = with lib; {
          description = "Local-first, non-invasive issue tracker storing tasks in SQLite";
          homepage = "https://github.com/Dicklesworthstone/beads_rust";
          license = licenses.mit;
          mainProgram = "br";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "beads-rust" builders versions;
  default = meta.default;
}
