{ pkgs, lib, toolbox, toolboxLib }:

let
  inherit (toolboxLib.readData ./data.json) meta versions;

  builders = {
    default = version: versionData:
      let
        go = toolbox.go.versions.${versionData.go};
      in
      (pkgs.buildGoModule.override { inherit go; }) {
        pname = "beads-viewer";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "Dicklesworthstone";
          repo = "beads_viewer";
          rev = "v${version}";
          hash = versionData.sha256;
        };
        vendorHash = versionData.vendorHash;
        subPackages = [ "cmd/bv" ];
        doCheck = false;

        postPatch = ''
          goVer="$(${go}/bin/go env GOVERSION | sed 's/^go//')"
          sed -i "s/^go .*/go $goVer/" go.mod
        '';
        env.GOTOOLCHAIN = "auto";
        ldflags = [ "-X" "github.com/Dicklesworthstone/beads_viewer/pkg/version.Version=v${version}" ];

        meta = with lib; {
          description = "Terminal UI for the Beads issue tracker with dependency graph visualization";
          homepage = "https://github.com/Dicklesworthstone/beads_viewer";
          license = licenses.mit;
          mainProgram = "bv";
        };
      };
  };
in
{
  versions = toolboxLib.buildVersions "beads-viewer" builders versions;
  default = meta.default;
}
